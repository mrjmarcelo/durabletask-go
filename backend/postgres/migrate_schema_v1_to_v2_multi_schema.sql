-- ========================================
-- Multi-Schema Migration: v1 to v2
-- ========================================
-- This script migrates from the old schema (schema_v1.sql) to the new
-- partitioned schema (schema.sql) for multiple schemas.
--
-- PREREQUISITES:
-- - External tables (golfinstancesdetails, golfsecondaryids) must exist in each schema
-- - Sufficient disk space for duplicate tables during migration
-- - Database user must have CREATE, ALTER, DROP privileges on all schemas
-- - Application writes should be stopped during cutover (Phase 7)
--
-- ESTIMATED DOWNTIME:
-- - Data copy: Can be done live (no downtime)
-- Cutover: 1-5 minutes per schema (stop writes, rename tables, update FKs)
--
-- INSTRUCTIONS:
-- 1. Set dry_run to false for actual migration, true for validation only
-- 2. Run the script - it will process all schemas in the list
-- 3. For each schema, Phases 1-6 run while application is running
-- 4. Stop application writes for all schemas
-- 5. Run Phase 7 (cutover) for all schemas
-- 6. Resume application writes
-- 7. After successful migration, run Phase 9 (cleanup) for all schemas
--
-- CONFIGURATION:
-- Set dry_run to true by changing the value below in the DO block
-- Look for: dry_run BOOLEAN := false; in the DECLARE section

-- Performance tuning options (adjust based on your environment)
SET statement_timeout = '300s';  -- 5 minutes
SET lock_timeout = '30s';
SET work_mem = '256MB';
-- ========================================

DO $$
DECLARE
    current_schema_name TEXT;
    dry_run BOOLEAN := false;  -- Set to true for dry-run mode, false for actual migration
    schemas TEXT[] := ARRAY[
        'asn_listener_service',
        'asn_status_listener_service',
        'b2b_inbound_router_service',
        'crossdock_ack_nack_service',
        'crossdock_workorder_service',
        'emea_crossdock_service',
        'fe_listener_service',
        'fil_oic_listener_service',
        'ibasn_ack_nack_service',
        'ibasn_process',
        'ibasn_receipt_ack_nack_service',
        'ibasn_receipt_service',
        'ibasn_service',
        'milestone_processing_service',
        'nf_request_service',
        'nf_response_service',
        'oic_listener_service',
        'oic_ptm_listener_service',
        'ptm_asn_ack_nack_service',
        'ptmasn_listener_service',
        'ship_mode_change_ack_nack_service',
        'ship_mode_change_determination_service',
        'shipment_edd_event_processing_service',
        'sn_ack_nack_service',
        'sn_listener_service',
        'sp_response_processing_service',
        'three_plasn_service',
        'transload_reverse_manifest_service',
        'wo_ack_nack_service',
        'wo_cancel_service',
        'wo_change_ack_service',
        'wo_change_service',
        'wo_status_update_service',
        'work_order_download_service',
        'work_order_listener_service',
        'work_order_release_service'
    ];

    failed_schemas TEXT[] := '{}';
    skipped_schemas TEXT[] := '{}';
    success_count INT := 0;
    error_message TEXT;
    
    -- Variables for each phase
    old_tables_exist BOOLEAN;
    new_tables_exist BOOLEAN;
    old_suffix_tables_exist BOOLEAN;
    migration_table_exists BOOLEAN;
    migration_completed BOOLEAN;
    row_count BIGINT;
    terminal_with_lock_count BIGINT;
    unlocked_without_infinity_count BIGINT;
    old_instances_count BIGINT;
    new_instances_count BIGINT;
    old_history_count BIGINT;
    new_history_count BIGINT;
    old_newevents_count BIGINT;
    new_newevents_count BIGINT;
    old_newtasks_count BIGINT;
    new_newtasks_count BIGINT;
    i INT;
BEGIN
    FOREACH current_schema_name IN ARRAY schemas
    LOOP
        BEGIN
            -- Set search path to this schema
            PERFORM set_config('search_path', current_schema_name, false);
            
            -- Check if schema exists
            IF NOT EXISTS (SELECT 1 FROM information_schema.schemata s WHERE s.schema_name = current_schema_name) THEN
                RAISE WARNING 'ERROR: Schema % does not exist in the database. Skipping.', current_schema_name;
                failed_schemas := array_append(failed_schemas, current_schema_name);
                CONTINUE;
            END IF;
            
            RAISE NOTICE '==============================';
            RAISE NOTICE 'Starting migration for schema: %', current_schema_name;
            RAISE NOTICE '==============================';
            
            -- Check dry-run mode
            IF dry_run THEN
                RAISE NOTICE 'DRY-RUN MODE: No changes will be made. This is for validation only.';
            ELSE
                RAISE NOTICE 'LIVE MODE: Changes will be made to the database.';
            END IF;
            
            -- ========================================
            -- Phase 0: Pre-flight Checks
            -- ========================================
            -- Check if old tables exist
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'instances'
                AND table_schema = current_schema()
            ) INTO old_tables_exist;

            -- Check if _v2 tables exist
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'instances_v2'
                AND table_schema = current_schema()
            ) INTO new_tables_exist;

            -- Check if _v1 tables exist (indicates migration completed)
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'instances_v1'
                AND table_schema = current_schema()
            ) INTO old_suffix_tables_exist;

            -- Check if migration tracking table exists
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'schema_migrations'
                AND table_schema = current_schema()
            ) INTO migration_table_exists;

            -- Check if migration already completed via schema_migrations table
            IF migration_table_exists THEN
                SELECT EXISTS (
                    SELECT 1 FROM schema_migrations
                    WHERE migration_name = 'v1_to_v2'
                    AND phase = 'Phase 7'
                    AND status = 'completed'
                ) INTO migration_completed;
            ELSE
                migration_completed := false;
            END IF;

            -- Migration already completed
            IF migration_completed THEN
                RAISE NOTICE 'SKIPPED: Migration already completed for schema %. Found v1_to_v2 migration with Phase 7 completed status.', current_schema_name;
                skipped_schemas := array_append(skipped_schemas, current_schema_name);
                CONTINUE;
            END IF;

            -- Migration in progress (incomplete)
            IF new_tables_exist AND NOT old_tables_exist THEN
                RAISE EXCEPTION 'Migration is in progress. The instances_v2 table exists but instances does not. Complete the current migration by running Phase 7 (cutover), or execute Phase 8 (rollback) to revert.';
            END IF;

            -- Old schema not found (already on new schema)
            IF NOT old_tables_exist THEN
                RAISE NOTICE 'SKIPPED: Old schema tables not found for schema %. This database may already be on the new schema.', current_schema_name;
                skipped_schemas := array_append(skipped_schemas, current_schema_name);
                CONTINUE;
            END IF;

            -- Check if old table is empty
            SELECT COUNT(*) INTO row_count FROM instances;
            IF row_count = 0 THEN
                RAISE NOTICE 'INFO: Old table instances is empty for schema %. Structure will still be migrated.', current_schema_name;
            END IF;

            RAISE NOTICE 'Phase 0: Pre-flight checks passed. Migration can proceed.';

            -- ========================================
            -- Phase 1: Preparation
            -- ========================================
            
            IF NOT dry_run THEN
                -- Create persistent sequence backup table (not TEMP to survive COMMIT)
                CREATE TABLE IF NOT EXISTS migration_sequence_backup (
                    seq_name TEXT PRIMARY KEY,
                    last_value BIGINT,
                    backup_time TIMESTAMP DEFAULT NOW()
                );

                INSERT INTO migration_sequence_backup (seq_name, last_value)
                SELECT 'instances_sequencenumber_seq', last_value FROM instances_sequencenumber_seq
                UNION ALL
                SELECT 'history_sequencenumber_seq', last_value FROM history_sequencenumber_seq
                UNION ALL
                SELECT 'newevents_sequencenumber_seq', last_value FROM newevents_sequencenumber_seq
                UNION ALL
                SELECT 'newtasks_sequencenumber_seq', last_value FROM newtasks_sequencenumber_seq
                ON CONFLICT (seq_name) DO UPDATE SET last_value = EXCLUDED.last_value, backup_time = NOW();

                -- Create schema_migrations tracking table
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    migration_name TEXT PRIMARY KEY,
                    phase TEXT,
                    status TEXT,
                    executed_at TIMESTAMP DEFAULT NOW(),
                    details TEXT
                );

                -- Record migration start
                INSERT INTO schema_migrations (migration_name, phase, status, details)
                VALUES ('v1_to_v2', 'Phase 1', 'started', 'Sequence backup and tracking tables created')
                ON CONFLICT (migration_name) DO UPDATE SET phase = 'Phase 1', status = 'started', executed_at = NOW(), details = EXCLUDED.details;
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create migration_sequence_backup and schema_migrations tables';
            END IF;

            RAISE NOTICE 'Phase 1: Sequence backup and tracking tables created';

            -- ========================================
            -- Phase 2: Create New Tables with _v2 suffix
            -- ========================================

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 2', status = 'started', details = 'Creating _v2 tables'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- ========================================
            -- instances_v2 Table
            -- ========================================
            IF NOT dry_run THEN
                CREATE TABLE instances_v2 (
                    SequenceNumber BIGSERIAL,
                    InstanceID TEXT NOT NULL,
                    ExecutionID TEXT NOT NULL,
                    Name TEXT NOT NULL,
                    Version TEXT NULL,
                    RuntimeStatus TEXT NOT NULL,
                    CreatedTime TIMESTAMP NOT NULL DEFAULT NOW(),
                    LastUpdatedTime TIMESTAMP NOT NULL DEFAULT NOW(),
                    CompletedTime TIMESTAMP NULL,
                    DequeueCount INTEGER NOT NULL DEFAULT 0,
                    LockedBy TEXT NULL,
                    LockExpiration TIMESTAMP NULL DEFAULT '-infinity',
                    Input TEXT NULL,
                    Output TEXT NULL,
                    CustomStatus TEXT NULL,
                    FailureDetails BYTEA NULL,
                    ParentInstanceID TEXT NULL,
                    PRIMARY KEY (InstanceID)
                );

                ALTER TABLE instances_v2 SET (fillfactor = 70);
                ALTER TABLE instances_v2 SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.02, autovacuum_analyze_threshold = 500);

                CREATE INDEX IX_instances_v2_ParentInstanceID ON instances_v2 (ParentInstanceID);
                CREATE INDEX IX_instances_v2_RuntimeStatus_NonTerminal ON instances_v2 (RuntimeStatus) WHERE RuntimeStatus IN ('PENDING', 'RUNNING', 'SUSPENDED', 'CONTINUED_AS_NEW');
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create instances_v2 table with indexes';
            END IF;

            RAISE NOTICE 'Phase 2: instances_v2 table created';

            -- ========================================
            -- history_v2 Table (with 128 partitions)
            -- ========================================
            IF NOT dry_run THEN
                CREATE TABLE history_v2 (
                    InstanceID TEXT NOT NULL,
                    SequenceNumber BIGSERIAL NOT NULL,
                    EventPayload BYTEA NOT NULL,
                    PRIMARY KEY (InstanceID, SequenceNumber)
                ) PARTITION BY HASH (InstanceID);
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create history_v2 partitioned table';
            END IF;

            -- Create 128 partitions for history_v2 with error handling
            IF NOT dry_run THEN
                FOR i IN 0..127 LOOP
                    BEGIN
                        EXECUTE format('CREATE TABLE history_v2_%s PARTITION OF history_v2 FOR VALUES WITH (MODULUS 128, REMAINDER %s)', lpad(i::text, 4, '0'), i::text);
                        EXECUTE format('ALTER TABLE history_v2_%s SET (fillfactor = 100)', lpad(i::text, 4, '0'));
                        EXECUTE format('ALTER TABLE history_v2_%s SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 2000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 1000)', lpad(i::text, 4, '0'));
                    EXCEPTION WHEN OTHERS THEN
                        RAISE EXCEPTION 'Failed to create history_v2 partition %04s: %', i, SQLERRM;
                    END;
                END LOOP;
                RAISE NOTICE 'Created 128 partitions for history_v2';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create 128 partitions for history_v2';
            END IF;

            RAISE NOTICE 'Phase 2: history_v2 table with 128 partitions created';

            -- ========================================
            -- newevents_v2 Table (with 128 partitions)
            -- ========================================
            IF NOT dry_run THEN
                CREATE TABLE newevents_v2 (
                    SequenceNumber BIGSERIAL,
                    InstanceID TEXT NOT NULL,
                    ExecutionID TEXT NULL,
                    Timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
                    VisibleTime TIMESTAMP NULL,
                    EventPayload BYTEA NOT NULL,
                    UNIQUE (InstanceID, SequenceNumber)
                ) PARTITION BY HASH (InstanceID);
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create newevents_v2 partitioned table';
            END IF;

            -- Create 128 partitions for newevents_v2 with error handling
            IF NOT dry_run THEN
                FOR i IN 0..127 LOOP
                    BEGIN
                        EXECUTE format('CREATE TABLE newevents_v2_%s PARTITION OF newevents_v2 FOR VALUES WITH (MODULUS 128, REMAINDER %s)', lpad(i::text, 4, '0'), i::text);
                        EXECUTE format('ALTER TABLE newevents_v2_%s SET (fillfactor = 70)', lpad(i::text, 4, '0'));
                        EXECUTE format('ALTER TABLE newevents_v2_%s SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 500, autovacuum_analyze_scale_factor = 0.01, autovacuum_analyze_threshold = 200)', lpad(i::text, 4, '0'));
                    EXCEPTION WHEN OTHERS THEN
                        RAISE EXCEPTION 'Failed to create newevents_v2 partition %04s: %', i, SQLERRM;
                    END;
                END LOOP;
                RAISE NOTICE 'Created 128 partitions for newevents_v2';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create 128 partitions for newevents_v2';
            END IF;

            RAISE NOTICE 'Phase 2: newevents_v2 table with 128 partitions created';

            -- ========================================
            -- newtasks_v2 Table
            -- ========================================
            IF NOT dry_run THEN
                CREATE TABLE newtasks_v2 (
                    SequenceNumber BIGSERIAL PRIMARY KEY,
                    InstanceID TEXT NOT NULL,
                    ExecutionID TEXT NULL,
                    Timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
                    DequeueCount INTEGER NOT NULL DEFAULT 0,
                    LockedBy TEXT NULL,
                    LockExpiration TIMESTAMP NULL,
                    EventPayload BYTEA NOT NULL,
                    UNIQUE (InstanceID, SequenceNumber)
                );

                ALTER TABLE newtasks_v2 SET (fillfactor = 70);
                ALTER TABLE newtasks_v2 SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 200, autovacuum_analyze_scale_factor = 0.01, autovacuum_analyze_threshold = 100);
            ELSE
                RAISE NOTICE 'DRY-RUN: Would create newtasks_v2 table with indexes';
            END IF;

            RAISE NOTICE 'Phase 2: newtasks_v2 table created';

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 2', status = 'completed', details = 'All _v2 tables created'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- ========================================
            -- Phase 3: Sequence Continuity
            -- ========================================

            IF NOT dry_run THEN
                PERFORM setval('instances_v2_sequencenumber_seq', 
                    (SELECT last_value FROM instances_sequencenumber_seq));
                PERFORM setval('history_v2_sequencenumber_seq', 
                    (SELECT last_value FROM history_sequencenumber_seq));
                PERFORM setval('newevents_v2_sequencenumber_seq', 
                    (SELECT last_value FROM newevents_sequencenumber_seq));
                PERFORM setval('newtasks_v2_sequencenumber_seq', 
                    (SELECT last_value FROM newtasks_sequencenumber_seq));
            ELSE
                RAISE NOTICE 'DRY-RUN: Would set sequence continuity';
            END IF;

            RAISE NOTICE 'Phase 3: Sequence continuity setup completed';

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 3', status = 'completed', details = 'Sequence continuity set'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- ========================================
            -- Phase 4: Data Migration
            -- ========================================

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 4', status = 'started', details = 'Migrating data'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- Migrate instances with LockExpiration business logic
            IF NOT dry_run THEN
                INSERT INTO instances_v2 (
                    SequenceNumber, InstanceID, ExecutionID, Name, Version, RuntimeStatus,
                    CreatedTime, LastUpdatedTime, CompletedTime,
                    DequeueCount, LockedBy, LockExpiration,
                    Input, Output, CustomStatus, FailureDetails, ParentInstanceID
                )
                SELECT 
                    SequenceNumber, InstanceID, ExecutionID, Name, Version, RuntimeStatus,
                    CreatedTime,
                    LastUpdatedTime,
                    CompletedTime,
                    0 AS DequeueCount,
                    LockedBy, 
                    CASE 
                        WHEN (LockExpiration IS NOT NULL)
                            THEN LockExpiration
                        WHEN RuntimeStatus IN ('COMPLETED', 'FAILED', 'TERMINATED', 'CANCELED') 
                            THEN NULL
                        WHEN (RuntimeStatus = 'PENDING') 
                            THEN '-infinity'
                        ELSE NOW()
                    END AS LockExpiration,
                    Input, Output, CustomStatus, FailureDetails, ParentInstanceID
                FROM instances;
                
                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE 'Migrated % rows to instances_v2', row_count;
            ELSE
                SELECT COUNT(*) INTO row_count FROM instances;
                RAISE NOTICE 'DRY-RUN: Would migrate % rows to instances_v2', row_count;
            END IF;

            RAISE NOTICE 'Phase 4: instances data migrated';

            -- Migrate history
            IF NOT dry_run THEN
                INSERT INTO history_v2 (InstanceID, SequenceNumber, EventPayload)
                SELECT InstanceID, SequenceNumber, EventPayload
                FROM history;
                
                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE 'Migrated % rows to history_v2', row_count;
            ELSE
                SELECT COUNT(*) INTO row_count FROM history;
                RAISE NOTICE 'DRY-RUN: Would migrate % rows to history_v2', row_count;
            END IF;

            RAISE NOTICE 'Phase 4: history data migrated';

            -- Migrate newevents (without DequeueCount and LockedBy)
            IF NOT dry_run THEN
                INSERT INTO newevents_v2 (
                    SequenceNumber, InstanceID, ExecutionID, Timestamp, VisibleTime, EventPayload
                )
                SELECT 
                    SequenceNumber, InstanceID, ExecutionID,
                    Timestamp,
                    VisibleTime,
                    EventPayload
                FROM newevents;
                
                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE 'Migrated % rows to newevents_v2', row_count;
            ELSE
                SELECT COUNT(*) INTO row_count FROM newevents;
                RAISE NOTICE 'DRY-RUN: Would migrate % rows to newevents_v2', row_count;
            END IF;

            RAISE NOTICE 'Phase 4: newevents data migrated';

            -- Migrate newtasks
            IF NOT dry_run THEN
                INSERT INTO newtasks_v2 (
                    SequenceNumber, InstanceID, ExecutionID, Timestamp,
                    DequeueCount, LockedBy, LockExpiration, EventPayload
                )
                SELECT 
                    SequenceNumber, InstanceID, ExecutionID,
                    Timestamp,
                    DequeueCount, LockedBy,
                    LockExpiration,
                    EventPayload
                FROM newtasks;
                
                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE 'Migrated % rows to newtasks_v2', row_count;
            ELSE
                SELECT COUNT(*) INTO row_count FROM newtasks;
                RAISE NOTICE 'DRY-RUN: Would migrate % rows to newtasks_v2', row_count;
            END IF;

            RAISE NOTICE 'Phase 4: newtasks data migrated';

            -- Re-backup sequences after data migration (for cutover)
            IF NOT dry_run THEN
                INSERT INTO migration_sequence_backup (seq_name, last_value)
                SELECT 'instances_sequencenumber_seq', last_value FROM instances_sequencenumber_seq
                UNION ALL
                SELECT 'history_sequencenumber_seq', last_value FROM history_sequencenumber_seq
                UNION ALL
                SELECT 'newevents_sequencenumber_seq', last_value FROM newevents_sequencenumber_seq
                UNION ALL
                SELECT 'newtasks_sequencenumber_seq', last_value FROM newtasks_sequencenumber_seq
                ON CONFLICT (seq_name) DO UPDATE SET last_value = EXCLUDED.last_value, backup_time = NOW();
                
                RAISE NOTICE 'Re-backed up sequences after data migration';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would re-backup sequences';
            END IF;

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 4', status = 'completed', details = 'All data migrated'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- ========================================
            -- Phase 5: Update External Table References to _v2 Tables
            -- ========================================

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 5', status = 'started', details = 'Updating external FKs'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            IF NOT dry_run THEN
                -- Drop old foreign key from golfinstancesdetails (with IF EXISTS)
                ALTER TABLE golfinstancesdetails 
                DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

                -- Add new foreign key to instances_v2
                ALTER TABLE golfinstancesdetails 
                ADD CONSTRAINT golfinstancesdetails_instanceid_fkey 
                FOREIGN KEY (instanceid) REFERENCES instances_v2(instanceid) ON DELETE CASCADE;
            ELSE
                RAISE NOTICE 'DRY-RUN: Would update golfinstancesdetails FK to reference instances_v2';
            END IF;

            RAISE NOTICE 'Phase 5: External table references updated to _v2 tables';

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 5', status = 'completed', details = 'External FKs updated'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- ========================================
            -- Phase 6: Data Validation
            -- ========================================

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 6', status = 'started', details = 'Validating data'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            -- Row count verification
            SELECT COUNT(*) INTO old_instances_count FROM instances;
            SELECT COUNT(*) INTO new_instances_count FROM instances_v2;
            SELECT COUNT(*) INTO old_history_count FROM history;
            SELECT COUNT(*) INTO new_history_count FROM history_v2;
            SELECT COUNT(*) INTO old_newevents_count FROM newevents;
            SELECT COUNT(*) INTO new_newevents_count FROM newevents_v2;
            SELECT COUNT(*) INTO old_newtasks_count FROM newtasks;
            SELECT COUNT(*) INTO new_newtasks_count FROM newtasks_v2;
            
            RAISE NOTICE 'Row count validation:';
            RAISE NOTICE '  instances: old=%, new=%', old_instances_count, new_instances_count;
            RAISE NOTICE '  history: old=%, new=%', old_history_count, new_history_count;
            RAISE NOTICE '  newevents: old=%, new=%', old_newevents_count, new_newevents_count;
            RAISE NOTICE '  newtasks: old=%, new=%', old_newtasks_count, new_newtasks_count;
            
            IF old_instances_count != new_instances_count THEN
                RAISE EXCEPTION 'instances row count mismatch: old=%, new=%', old_instances_count, new_instances_count;
            END IF;
            
            IF old_history_count != new_history_count THEN
                RAISE EXCEPTION 'history row count mismatch: old=%, new=%', old_history_count, new_history_count;
            END IF;
            
            IF old_newevents_count != new_newevents_count THEN
                RAISE EXCEPTION 'newevents row count mismatch: old=%, new=%', old_newevents_count, new_newevents_count;
            END IF;
            
            IF old_newtasks_count != new_newtasks_count THEN
                RAISE EXCEPTION 'newtasks row count mismatch: old=%, new=%', old_newtasks_count, new_newtasks_count;
            END IF;
            
            RAISE NOTICE 'Phase 6: Row count validation passed';

            -- LockExpiration transformation validation
            -- Verify terminal statuses have NULL LockExpiration
            SELECT COUNT(*) INTO terminal_with_lock_count
            FROM instances_v2 
            WHERE RuntimeStatus IN ('COMPLETED', 'FAILED', 'TERMINATED', 'CANCELED')
            AND LockExpiration IS NOT NULL;
            
            IF terminal_with_lock_count > 0 THEN
                RAISE WARNING 'Found % terminal instances with non-NULL LockExpiration', terminal_with_lock_count;
            END IF;
            
            -- Verify unlocked instances have '-infinity'
            SELECT COUNT(*) INTO unlocked_without_infinity_count
            FROM instances_v2 
            WHERE (LockedBy IS NULL)
            AND LockExpiration != '-infinity';
            
            IF unlocked_without_infinity_count > 0 THEN
                RAISE WARNING 'Found % unlocked instances without LockExpiration=-infinity', unlocked_without_infinity_count;
            END IF;
            
            RAISE NOTICE 'Phase 6: LockExpiration transformation validation completed';

            RAISE NOTICE 'Phase 6: Data validation completed';

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 6', status = 'completed', details = 'Data validation passed'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            RAISE NOTICE 'Phases 1-6 completed successfully for schema: %', current_schema_name;
            RAISE NOTICE 'IMPORTANT: Stop application writes before proceeding to Phase 7';

            -- ========================================
            -- Phase 7: Cutover
            -- ========================================

            -- Pre-cutover verification
            IF NOT dry_run THEN
                -- Verify _v2 tables exist
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instances_v2' AND table_schema = current_schema()) THEN
                    RAISE EXCEPTION 'instances_v2 table not found. Cannot proceed with cutover.';
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'history_v2' AND table_schema = current_schema()) THEN
                    RAISE EXCEPTION 'history_v2 table not found. Cannot proceed with cutover.';
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'newevents_v2' AND table_schema = current_schema()) THEN
                    RAISE EXCEPTION 'newevents_v2 table not found. Cannot proceed with cutover.';
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'newtasks_v2' AND table_schema = current_schema()) THEN
                    RAISE EXCEPTION 'newtasks_v2 table not found. Cannot proceed with cutover.';
                END IF;
                
                -- Verify _v2 tables contain data
                IF (SELECT COUNT(*) FROM instances_v2) = 0 THEN
                    RAISE NOTICE 'INFO: instances_v2 table is empty. Proceeding with cutover anyway.';
                END IF;
                
                -- Verify old tables still exist
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'instances' AND table_schema = current_schema()) THEN
                    RAISE EXCEPTION 'instances table not found. Cannot proceed with cutover.';
                END IF;
                
                RAISE NOTICE 'Pre-cutover verification passed.';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would perform pre-cutover verification';
            END IF;

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 7', status = 'started', details = 'Cutover in progress'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            IF NOT dry_run THEN
                -- Rename old tables to _v1
                ALTER TABLE instances RENAME TO instances_v1;
                ALTER TABLE history RENAME TO history_v1;
                ALTER TABLE newevents RENAME TO newevents_v1;
                ALTER TABLE newtasks RENAME TO newtasks_v1;

                RAISE NOTICE 'Old tables renamed to _v1';

                -- Rename _v2 tables to final names
                ALTER TABLE instances_v2 RENAME TO instances;
                ALTER TABLE history_v2 RENAME TO history;
                ALTER TABLE newevents_v2 RENAME TO newevents;
                ALTER TABLE newtasks_v2 RENAME TO newtasks;

                RAISE NOTICE '_v2 tables renamed to final names';

                -- Update golfinstancesdetails foreign key to reference final instances
                ALTER TABLE golfinstancesdetails 
                DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

                ALTER TABLE golfinstancesdetails 
                ADD CONSTRAINT golfinstancesdetails_instanceid_fkey 
                FOREIGN KEY (instanceid) REFERENCES instances(instanceid) ON DELETE CASCADE;

                RAISE NOTICE 'Foreign key updated to reference final instances table';

                -- Rename old sequences to add _v1 suffix at end (if they exist)
                BEGIN
                    ALTER SEQUENCE instances_sequencenumber_seq RENAME TO instances_sequencenumber_seq_v1;
                EXCEPTION WHEN UNDEFINED_TABLE THEN
                    RAISE NOTICE 'Old sequence instances_sequencenumber_seq does not exist, skipping rename.';
                END;
                BEGIN
                    ALTER SEQUENCE history_sequencenumber_seq RENAME TO history_sequencenumber_seq_v1;
                EXCEPTION WHEN UNDEFINED_TABLE THEN
                    RAISE NOTICE 'Old sequence history_sequencenumber_seq does not exist, skipping rename.';
                END;
                BEGIN
                    ALTER SEQUENCE newevents_sequencenumber_seq RENAME TO newevents_sequencenumber_seq_v1;
                EXCEPTION WHEN UNDEFINED_TABLE THEN
                    RAISE NOTICE 'Old sequence newevents_sequencenumber_seq does not exist, skipping rename.';
                END;
                BEGIN
                    ALTER SEQUENCE newtasks_sequencenumber_seq RENAME TO newtasks_sequencenumber_seq_v1;
                EXCEPTION WHEN UNDEFINED_TABLE THEN
                    RAISE NOTICE 'Old sequence newtasks_sequencenumber_seq does not exist, skipping rename.';
                END;

                RAISE NOTICE 'Old sequences renamed with _v1 suffix (where they existed)';

                -- Rename new sequences to remove _v2 suffix from end
                ALTER SEQUENCE instances_v2_sequencenumber_seq RENAME TO instances_sequencenumber_seq;
                ALTER SEQUENCE history_v2_sequencenumber_seq RENAME TO history_sequencenumber_seq;
                ALTER SEQUENCE newevents_v2_sequencenumber_seq RENAME TO newevents_sequencenumber_seq;
                ALTER SEQUENCE newtasks_v2_sequencenumber_seq RENAME TO newtasks_sequencenumber_seq;

                RAISE NOTICE 'New sequences renamed to remove _v2 suffix';

                -- Rename old indexes to add _v1 suffix at end (if they exist)
                BEGIN
                    ALTER INDEX IX_Instances_ParentInstanceID RENAME TO IX_Instances_ParentInstanceID_v1;
                EXCEPTION WHEN UNDEFINED_TABLE THEN
                    RAISE NOTICE 'Old index IX_Instances_ParentInstanceID does not exist, skipping rename.';
                END;
                BEGIN
                    ALTER INDEX IX_Instances_RuntimeStatus_NonTerminal RENAME TO IX_Instances_RuntimeStatus_NonTerminal_v1;
                EXCEPTION WHEN UNDEFINED_TABLE THEN
                    RAISE NOTICE 'Old index IX_Instances_RuntimeStatus_NonTerminal does not exist, skipping rename.';
                END;

                RAISE NOTICE 'Old indexes renamed with _v1 suffix (where they existed)';

                -- Rename new indexes to remove _v2 suffix from end
                ALTER INDEX IX_instances_v2_ParentInstanceID RENAME TO IX_Instances_ParentInstanceID;
                ALTER INDEX IX_instances_v2_RuntimeStatus_NonTerminal RENAME TO IX_Instances_RuntimeStatus_NonTerminal;

                RAISE NOTICE 'New indexes renamed to remove _v2 suffix';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would perform cutover (rename tables, update FKs, rename sequences and indexes)';
            END IF;

            IF NOT dry_run THEN
                UPDATE schema_migrations SET phase = 'Phase 7', status = 'completed', details = 'Cutover completed successfully'
                WHERE migration_name = 'v1_to_v2';
            END IF;

            RAISE NOTICE 'Phase 7: Cutover completed successfully for schema: %', current_schema_name;
            RAISE NOTICE 'IMPORTANT: Resume application writes for schema: %', current_schema_name;

            success_count := success_count + 1;
            RAISE NOTICE '==============================';
            RAISE NOTICE 'Migration completed successfully for schema: %', current_schema_name;
            RAISE NOTICE '==============================';
            
        EXCEPTION WHEN OTHERS THEN
            failed_schemas := array_append(failed_schemas, current_schema_name);
            error_message := SQLERRM;
            RAISE WARNING 'Migration failed for schema %: %', current_schema_name, error_message;
            
            -- Restore search path on error
            PERFORM set_config('search_path', 'public', false);
        END;
    END LOOP;
    
    -- Restore default search path
    PERFORM set_config('search_path', 'public', false);
    
    -- Report results
    RAISE NOTICE '==============================';
    RAISE NOTICE 'MULTI-SCHEMA MIGRATION SUMMARY';
    RAISE NOTICE '==============================';
    RAISE NOTICE 'Total schemas processed: %', COALESCE(array_length(schemas, 1), 0);
    RAISE NOTICE 'Successful migrations: %', success_count;
    RAISE NOTICE 'Skipped migrations: %', COALESCE(array_length(skipped_schemas, 1), 0);
    RAISE NOTICE 'Failed migrations: %', COALESCE(array_length(failed_schemas, 1), 0);
    IF array_length(skipped_schemas, 1) > 0 THEN
        RAISE NOTICE 'Skipped schemas: %', array_to_string(skipped_schemas, ', ');
    END IF;
    IF array_length(failed_schemas, 1) > 0 THEN
        RAISE NOTICE 'Failed schemas: %', array_to_string(failed_schemas, ', ');
    END IF;
    RAISE NOTICE '==============================';
    
    IF array_length(failed_schemas, 1) > 0 THEN
        RAISE WARNING 'Some schemas failed to migrate. Please review the errors above.';
    ELSE
        RAISE NOTICE 'All schemas processed successfully!';
    END IF;
END $$;
