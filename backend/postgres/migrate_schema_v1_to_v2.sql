-- ============================================================================
-- Schema Migration: v1 to v2
-- ============================================================================
-- This script migrates from the old schema (schema_old.sql) to the new
-- partitioned schema (schema.sql).
--
-- PREREQUISITES:
-- - External tables (golfinstancesdetails, golfsecondaryids) must exist
-- - Sufficient disk space for duplicate tables during migration
-- - Database user must have CREATE, ALTER, DROP privileges
-- - Application writes should be stopped during cutover (Phase 7)
--
-- ESTIMATED DOWNTIME:
-- - Data copy: Can be done live (no downtime)
-- - Cutover: 1-5 minutes (stop writes, rename tables, update FKs)
--
-- INSTRUCTIONS:
-- 1. Set dry_run to false for actual migration, true for validation only
-- 2. Run Phases 1-6 (can be done while application is running)
-- 3. Stop application writes
-- 4. Run Phase 7 (cutover)
-- 5. Resume application writes
-- 6. After successful migration, run Phase 9 (cleanup)
--
-- CONFIGURATION:
-- Set dry_run to true by changing the value below in the DO block
-- Look for: dry_run BOOLEAN := false; in the DECLARE section

-- Performance tuning options (adjust based on your environment)
SET statement_timeout = '300s';  -- 5 minutes
SET lock_timeout = '30s';
SET work_mem = '256MB';
-- ============================================================================

-- ============================================================================
-- Phase 0: Pre-flight Checks
-- ============================================================================
-- Detect migration state and prevent re-execution on already-migrated databases
DO $$
DECLARE
    dry_run BOOLEAN := false;  -- Set to true for dry-run mode, false for actual migration
    old_tables_exist BOOLEAN;
    new_tables_exist BOOLEAN;
    old_suffix_tables_exist BOOLEAN;
    migration_table_exists BOOLEAN;
BEGIN
    -- Check if old tables exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'Instances'
        AND table_schema = current_schema()
    ) INTO old_tables_exist;

    -- Check if _new tables exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'Instances_new'
        AND table_schema = current_schema()
    ) INTO new_tables_exist;

    -- Check if _old tables exist (indicates migration completed)
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'Instances_old'
        AND table_schema = current_schema()
    ) INTO old_suffix_tables_exist;

    -- Check if migration tracking table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'schema_migrations'
        AND table_schema = current_schema()
    ) INTO migration_table_exists;

    -- Migration already completed
    IF old_suffix_tables_exist THEN
        RAISE EXCEPTION 'Migration already completed. The Instances_old table exists. To re-run migration, first execute Phase 9 (cleanup) to drop _old tables, or Phase 8 (rollback) if you need to revert.';
    END IF;

    -- Migration in progress (incomplete)
    IF new_tables_exist AND NOT old_tables_exist THEN
        RAISE EXCEPTION 'Migration is in progress. The Instances_new table exists but Instances does not. Complete the current migration by running Phase 7 (cutover), or execute Phase 8 (rollback) to revert.';
    END IF;

    -- Old schema not found (already on new schema)
    IF NOT old_tables_exist THEN
        RAISE EXCEPTION 'Old schema tables not found. This database may already be on the new schema. Expected Instances table to exist.';
    END IF;

    RAISE NOTICE 'Phase 0: Pre-flight checks passed. Migration can proceed.';
    
    -- Check dry-run mode
    IF dry_run THEN
        RAISE NOTICE 'DRY-RUN MODE: No changes will be made. This is for validation only.';
    ELSE
        RAISE NOTICE 'LIVE MODE: Changes will be made to the database.';
    END IF;
END $$;

BEGIN;

-- ============================================================================
-- Phase 1: Preparation
-- ============================================================================

-- Create persistent sequence backup table (not TEMP to survive COMMIT)
CREATE TABLE IF NOT EXISTS migration_sequence_backup (
    seq_name TEXT PRIMARY KEY,
    last_value BIGINT,
    backup_time TIMESTAMP DEFAULT NOW()
);

-- Record current sequence values for later restoration if needed
INSERT INTO migration_sequence_backup (seq_name, last_value)
SELECT 'Instances_SequenceNumber_seq', last_value FROM Instances_SequenceNumber_seq
UNION ALL
SELECT 'History_SequenceNumber_seq', last_value FROM History_SequenceNumber_seq
UNION ALL
SELECT 'NewEvents_SequenceNumber_seq', last_value FROM NewEvents_SequenceNumber_seq
UNION ALL
SELECT 'NewTasks_SequenceNumber_seq', last_value FROM NewTasks_SequenceNumber_seq
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

RAISE NOTICE 'Phase 1: Sequence backup and tracking tables created';

-- ============================================================================
-- Phase 2: Create New Tables with _new suffix
-- ============================================================================

-- Record Phase 2 start
UPDATE schema_migrations SET phase = 'Phase 2', status = 'started', details = 'Creating _new tables'
WHERE migration_name = 'v1_to_v2';

-- ============================================================================
-- Instances_new Table
-- ============================================================================
DO $$
BEGIN
    IF dry_run = 'false' THEN
        CREATE TABLE Instances_new (
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

        ALTER TABLE Instances_new SET (fillfactor = 70);
        ALTER TABLE Instances_new SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.02, autovacuum_analyze_threshold = 500);

        CREATE INDEX IX_Instances_new_ParentInstanceID ON Instances_new (ParentInstanceID);
        CREATE INDEX IX_Instances_new_RuntimeStatus_NonTerminal ON Instances_new (RuntimeStatus) WHERE RuntimeStatus IN ('PENDING', 'RUNNING', 'SUSPENDED', 'CONTINUED_AS_NEW');
    ELSE
        RAISE NOTICE 'DRY-RUN: Would create Instances_new table with indexes';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to create Instances_new table: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 2: Instances_new table created';

-- ============================================================================
-- History_new Table (with 128 partitions)
-- ============================================================================
DO $$
BEGIN
    IF dry_run = 'false' THEN
        CREATE TABLE History_new (
            InstanceID TEXT NOT NULL,
            SequenceNumber BIGSERIAL NOT NULL,
            EventPayload BYTEA NOT NULL,
            PRIMARY KEY (InstanceID, SequenceNumber)
        ) PARTITION BY HASH (InstanceID);
    ELSE
        RAISE NOTICE 'DRY-RUN: Would create History_new partitioned table';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to create History_new table: %', SQLERRM;
END $$;

-- Create 128 partitions for History_new with error handling
DO $$
DECLARE
    i INT;
BEGIN
    IF dry_run = 'false' THEN
        FOR i IN 0..127 LOOP
            BEGIN
                EXECUTE format('CREATE TABLE History_new_%04s PARTITION OF History_new FOR VALUES WITH (MODULUS 128, REMAINDER %s)', i, i);
                EXECUTE format('ALTER TABLE History_new_%04s SET (fillfactor = 100)', i);
                EXECUTE format('ALTER TABLE History_new_%04s SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 2000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 1000)', i);
            EXCEPTION WHEN OTHERS THEN
                RAISE EXCEPTION 'Failed to create History_new partition %04s: %', i, SQLERRM;
            END;
        END LOOP;
        RAISE NOTICE 'Created 128 partitions for History_new';
    ELSE
        RAISE NOTICE 'DRY-RUN: Would create 128 partitions for History_new';
    END IF;
END $$;

RAISE NOTICE 'Phase 2: History_new table with 128 partitions created';

-- ============================================================================
-- NewEvents_new Table (with 128 partitions)
-- ============================================================================
DO $$
BEGIN
    IF dry_run = 'false' THEN
        CREATE TABLE NewEvents_new (
            SequenceNumber BIGSERIAL,
            InstanceID TEXT NOT NULL,
            ExecutionID TEXT NULL,
            Timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
            VisibleTime TIMESTAMP NULL,
            EventPayload BYTEA NOT NULL,
            UNIQUE (InstanceID, SequenceNumber)
        ) PARTITION BY HASH (InstanceID);
    ELSE
        RAISE NOTICE 'DRY-RUN: Would create NewEvents_new partitioned table';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to create NewEvents_new table: %', SQLERRM;
END $$;

-- Create 128 partitions for NewEvents_new with error handling
DO $$
DECLARE
    i INT;
BEGIN
    IF dry_run = 'false' THEN
        FOR i IN 0..127 LOOP
            BEGIN
                EXECUTE format('CREATE TABLE NewEvents_new_%04s PARTITION OF NewEvents_new FOR VALUES WITH (MODULUS 128, REMAINDER %s)', i, i);
                EXECUTE format('ALTER TABLE NewEvents_new_%04s SET (fillfactor = 70)', i);
                EXECUTE format('ALTER TABLE NewEvents_new_%04s SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 500, autovacuum_analyze_scale_factor = 0.01, autovacuum_analyze_threshold = 200)', i);
            EXCEPTION WHEN OTHERS THEN
                RAISE EXCEPTION 'Failed to create NewEvents_new partition %04s: %', i, SQLERRM;
            END;
        END LOOP;
        RAISE NOTICE 'Created 128 partitions for NewEvents_new';
    ELSE
        RAISE NOTICE 'DRY-RUN: Would create 128 partitions for NewEvents_new';
    END IF;
END $$;

RAISE NOTICE 'Phase 2: NewEvents_new table with 128 partitions created';

-- ============================================================================
-- NewTasks_new Table
-- ============================================================================
DO $$
BEGIN
    IF dry_run = 'false' THEN
        CREATE TABLE NewTasks_new (
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

        ALTER TABLE NewTasks_new SET (fillfactor = 70);
        ALTER TABLE NewTasks_new SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 200, autovacuum_analyze_scale_factor = 0.01, autovacuum_analyze_threshold = 100);
    ELSE
        RAISE NOTICE 'DRY-RUN: Would create NewTasks_new table with indexes';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to create NewTasks_new table: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 2: NewTasks_new table created';

-- Record Phase 2 completion
UPDATE schema_migrations SET phase = 'Phase 2', status = 'completed', details = 'All _new tables created'
WHERE migration_name = 'v1_to_v2';

-- ============================================================================
-- Phase 3: Sequence Continuity
-- ============================================================================

UPDATE schema_migrations SET phase = 'Phase 3', status = 'started', details = 'Setting sequence continuity'
WHERE migration_name = 'v1_to_v2';

DO $$
BEGIN
    IF dry_run = 'false' THEN
        PERFORM setval('Instances_new_SequenceNumber_seq', 
            (SELECT last_value FROM Instances_SequenceNumber_seq));
        PERFORM setval('History_new_SequenceNumber_seq', 
            (SELECT last_value FROM History_SequenceNumber_seq));
        PERFORM setval('NewEvents_new_SequenceNumber_seq', 
            (SELECT last_value FROM NewEvents_SequenceNumber_seq));
        PERFORM setval('NewTasks_new_SequenceNumber_seq', 
            (SELECT last_value FROM NewTasks_SequenceNumber_seq));
    ELSE
        RAISE NOTICE 'DRY-RUN: Would set sequence continuity';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to set sequence continuity: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 3: Sequence continuity setup completed';

UPDATE schema_migrations SET phase = 'Phase 3', status = 'completed', details = 'Sequence continuity set'
WHERE migration_name = 'v1_to_v2';

-- ============================================================================
-- Phase 4: Data Migration
-- ============================================================================

UPDATE schema_migrations SET phase = 'Phase 4', status = 'started', details = 'Migrating data'
WHERE migration_name = 'v1_to_v2';

-- Migrate Instances with LockExpiration business logic
DO $$
DECLARE
    row_count BIGINT;
BEGIN
    IF dry_run = 'false' THEN
        INSERT INTO Instances_new (
            SequenceNumber, InstanceID, ExecutionID, Name, Version, RuntimeStatus,
            CreatedTime, LastUpdatedTime, CompletedTime,
            DequeueCount, LockedBy, LockExpiration,
            Input, Output, CustomStatus, FailureDetails, ParentInstanceID
        )
        SELECT 
            SequenceNumber, InstanceID, ExecutionID, Name, Version, RuntimeStatus,
            CreatedTime, LastUpdatedTime, CompletedTime,
            0 AS DequeueCount,
            LockedBy, 
            CASE 
                WHEN RuntimeStatus IN ('COMPLETED', 'FAILED', 'TERMINATED', 'CANCELED') 
                    THEN NULL
                WHEN (LockedBy IS NULL OR LockedBy = '') 
                     AND (LockExpiration IS NULL OR LockExpiration = '') 
                    THEN '-infinity'
                WHEN (LockedBy IS NOT NULL AND LockedBy != '') 
                     AND (LockExpiration IS NULL OR LockExpiration = '') 
                    THEN NOW()
                ELSE LockExpiration
            END AS LockExpiration,
            Input, Output, CustomStatus, FailureDetails, ParentInstanceID
        FROM Instances;
        
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Migrated % rows to Instances_new', row_count;
    ELSE
        SELECT COUNT(*) INTO row_count FROM Instances;
        RAISE NOTICE 'DRY-RUN: Would migrate % rows to Instances_new', row_count;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to migrate Instances data: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 4: Instances data migrated';

-- Migrate History
DO $$
DECLARE
    row_count BIGINT;
BEGIN
    IF dry_run = 'false' THEN
        INSERT INTO History_new (InstanceID, SequenceNumber, EventPayload)
        SELECT InstanceID, SequenceNumber, EventPayload
        FROM History;
        
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Migrated % rows to History_new', row_count;
    ELSE
        SELECT COUNT(*) INTO row_count FROM History;
        RAISE NOTICE 'DRY-RUN: Would migrate % rows to History_new', row_count;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to migrate History data: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 4: History data migrated';

-- Migrate NewEvents (without DequeueCount and LockedBy)
DO $$
DECLARE
    row_count BIGINT;
BEGIN
    IF dry_run = 'false' THEN
        INSERT INTO NewEvents_new (
            SequenceNumber, InstanceID, ExecutionID, Timestamp, VisibleTime, EventPayload
        )
        SELECT 
            SequenceNumber, InstanceID, ExecutionID, Timestamp, VisibleTime, EventPayload
        FROM NewEvents;
        
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Migrated % rows to NewEvents_new', row_count;
    ELSE
        SELECT COUNT(*) INTO row_count FROM NewEvents;
        RAISE NOTICE 'DRY-RUN: Would migrate % rows to NewEvents_new', row_count;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to migrate NewEvents data: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 4: NewEvents data migrated';

-- Migrate NewTasks
DO $$
DECLARE
    row_count BIGINT;
BEGIN
    IF dry_run = 'false' THEN
        INSERT INTO NewTasks_new (
            SequenceNumber, InstanceID, ExecutionID, Timestamp,
            DequeueCount, LockedBy, LockExpiration, EventPayload
        )
        SELECT 
            SequenceNumber, InstanceID, ExecutionID, Timestamp,
            DequeueCount, LockedBy, LockExpiration, EventPayload
        FROM NewTasks;
        
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RAISE NOTICE 'Migrated % rows to NewTasks_new', row_count;
    ELSE
        SELECT COUNT(*) INTO row_count FROM NewTasks;
        RAISE NOTICE 'DRY-RUN: Would migrate % rows to NewTasks_new', row_count;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to migrate NewTasks data: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 4: NewTasks data migrated';

-- Re-backup sequences after data migration (for cutover)
DO $$
BEGIN
    IF dry_run = 'false' THEN
        INSERT INTO migration_sequence_backup (seq_name, last_value)
        SELECT 'Instances_SequenceNumber_seq', last_value FROM Instances_SequenceNumber_seq
        UNION ALL
        SELECT 'History_SequenceNumber_seq', last_value FROM History_SequenceNumber_seq
        UNION ALL
        SELECT 'NewEvents_SequenceNumber_seq', last_value FROM NewEvents_SequenceNumber_seq
        UNION ALL
        SELECT 'NewTasks_SequenceNumber_seq', last_value FROM NewTasks_SequenceNumber_seq
        ON CONFLICT (seq_name) DO UPDATE SET last_value = EXCLUDED.last_value, backup_time = NOW();
        
        RAISE NOTICE 'Re-backed up sequences after data migration';
    ELSE
        RAISE NOTICE 'DRY-RUN: Would re-backup sequences';
    END IF;
END $$;

UPDATE schema_migrations SET phase = 'Phase 4', status = 'completed', details = 'All data migrated'
WHERE migration_name = 'v1_to_v2';

-- ============================================================================
-- Phase 5: Update External Table References to _new Tables
-- ============================================================================

UPDATE schema_migrations SET phase = 'Phase 5', status = 'started', details = 'Updating external FKs'
WHERE migration_name = 'v1_to_v2';

DO $$
BEGIN
    IF dry_run = 'false' THEN
        -- Drop old foreign key from golfinstancesdetails (with IF EXISTS)
        ALTER TABLE golfinstancesdetails 
        DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

        -- Add new foreign key to Instances_new
        ALTER TABLE golfinstancesdetails 
        ADD CONSTRAINT golfinstancesdetails_instanceid_fkey 
        FOREIGN KEY (instanceid) REFERENCES Instances_new(instanceid) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'DRY-RUN: Would update golfinstancesdetails FK to reference Instances_new';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to update external table references: %', SQLERRM;
END $$;

RAISE NOTICE 'Phase 5: External table references updated to _new tables';

UPDATE schema_migrations SET phase = 'Phase 5', status = 'completed', details = 'External FKs updated'
WHERE migration_name = 'v1_to_v2';

-- ============================================================================
-- Phase 6: Data Validation
-- ============================================================================

UPDATE schema_migrations SET phase = 'Phase 6', status = 'started', details = 'Validating data'
WHERE migration_name = 'v1_to_v2';

-- Row count verification
DO $$
DECLARE
    old_instances_count BIGINT;
    new_instances_count BIGINT;
    old_history_count BIGINT;
    new_history_count BIGINT;
    old_newevents_count BIGINT;
    new_newevents_count BIGINT;
    old_newtasks_count BIGINT;
    new_newtasks_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO old_instances_count FROM Instances;
    SELECT COUNT(*) INTO new_instances_count FROM Instances_new;
    SELECT COUNT(*) INTO old_history_count FROM History;
    SELECT COUNT(*) INTO new_history_count FROM History_new;
    SELECT COUNT(*) INTO old_newevents_count FROM NewEvents;
    SELECT COUNT(*) INTO new_newevents_count FROM NewEvents_new;
    SELECT COUNT(*) INTO old_newtasks_count FROM NewTasks;
    SELECT COUNT(*) INTO new_newtasks_count FROM NewTasks_new;
    
    RAISE NOTICE 'Row count validation:';
    RAISE NOTICE '  Instances: old=%, new=%', old_instances_count, new_instances_count;
    RAISE NOTICE '  History: old=%, new=%', old_history_count, new_history_count;
    RAISE NOTICE '  NewEvents: old=%, new=%', old_newevents_count, new_newevents_count;
    RAISE NOTICE '  NewTasks: old=%, new=%', old_newtasks_count, new_newtasks_count;
    
    IF old_instances_count != new_instances_count THEN
        RAISE EXCEPTION 'Instances row count mismatch: old=%, new=%', old_instances_count, new_instances_count;
    END IF;
    
    IF old_history_count != new_history_count THEN
        RAISE EXCEPTION 'History row count mismatch: old=%, new=%', old_history_count, new_history_count;
    END IF;
    
    IF old_newevents_count != new_newevents_count THEN
        RAISE EXCEPTION 'NewEvents row count mismatch: old=%, new=%', old_newevents_count, new_newevents_count;
    END IF;
    
    IF old_newtasks_count != new_newtasks_count THEN
        RAISE EXCEPTION 'NewTasks row count mismatch: old=%, new=%', old_newtasks_count, new_newtasks_count;
    END IF;
    
    RAISE NOTICE 'Phase 6: Row count validation passed';
END $$;

-- LockExpiration transformation validation
DO $$
DECLARE
    terminal_with_lock_count BIGINT;
    unlocked_without_infinity_count BIGINT;
BEGIN
    -- Verify terminal statuses have NULL LockExpiration
    SELECT COUNT(*) INTO terminal_with_lock_count
    FROM Instances_new 
    WHERE RuntimeStatus IN ('COMPLETED', 'FAILED', 'TERMINATED', 'CANCELED')
    AND LockExpiration IS NOT NULL;
    
    IF terminal_with_lock_count > 0 THEN
        RAISE WARNING 'Found % terminal instances with non-NULL LockExpiration', terminal_with_lock_count;
    END IF;
    
    -- Verify unlocked instances have '-infinity'
    SELECT COUNT(*) INTO unlocked_without_infinity_count
    FROM Instances_new 
    WHERE (LockedBy IS NULL OR LockedBy = '')
    AND LockExpiration != '-infinity';
    
    IF unlocked_without_infinity_count > 0 THEN
        RAISE WARNING 'Found % unlocked instances without LockExpiration=-infinity', unlocked_without_infinity_count;
    END IF;
    
    RAISE NOTICE 'Phase 6: LockExpiration transformation validation completed';
END $$;

RAISE NOTICE 'Phase 6: Data validation completed';

UPDATE schema_migrations SET phase = 'Phase 6', status = 'completed', details = 'Data validation passed'
WHERE migration_name = 'v1_to_v2';

COMMIT;

RAISE NOTICE 'Phases 1-6 completed successfully. Ready for cutover.';

-- ============================================================================
-- IMPORTANT: STOP APPLICATION WRITES BEFORE PROCEEDING TO PHASE 7
-- ============================================================================

-- ============================================================================
-- Phase 7: Cutover
-- ============================================================================

-- Pre-cutover verification
DO $$
BEGIN
    IF dry_run = 'false' THEN
        -- Verify _new tables exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Instances_new' AND table_schema = current_schema()) THEN
            RAISE EXCEPTION 'Instances_new table not found. Cannot proceed with cutover.';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'History_new' AND table_schema = current_schema()) THEN
            RAISE EXCEPTION 'History_new table not found. Cannot proceed with cutover.';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'NewEvents_new' AND table_schema = current_schema()) THEN
            RAISE EXCEPTION 'NewEvents_new table not found. Cannot proceed with cutover.';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'NewTasks_new' AND table_schema = current_schema()) THEN
            RAISE EXCEPTION 'NewTasks_new table not found. Cannot proceed with cutover.';
        END IF;
        
        -- Verify _new tables contain data
        IF (SELECT COUNT(*) FROM Instances_new) = 0 THEN
            RAISE EXCEPTION 'Instances_new table is empty. Cannot proceed with cutover.';
        END IF;
        
        -- Verify old tables still exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Instances' AND table_schema = current_schema()) THEN
            RAISE EXCEPTION 'Instances table not found. Cannot proceed with cutover.';
        END IF;
        
        RAISE NOTICE 'Pre-cutover verification passed.';
    ELSE
        RAISE NOTICE 'DRY-RUN: Would perform pre-cutover verification';
    END IF;
END $$;

BEGIN;

UPDATE schema_migrations SET phase = 'Phase 7', status = 'started', details = 'Cutover in progress'
WHERE migration_name = 'v1_to_v2';

DO $$
BEGIN
    IF dry_run = 'false' THEN
        -- Rename old tables to _old
        ALTER TABLE Instances RENAME TO Instances_old;
        ALTER TABLE History RENAME TO History_old;
        ALTER TABLE NewEvents RENAME TO NewEvents_old;
        ALTER TABLE NewTasks RENAME TO NewTasks_old;

        RAISE NOTICE 'Old tables renamed to _old';

        -- Rename _new tables to final names
        ALTER TABLE Instances_new RENAME TO Instances;
        ALTER TABLE History_new RENAME TO History;
        ALTER TABLE NewEvents_new RENAME TO NewEvents;
        ALTER TABLE NewTasks_new RENAME TO NewTasks;

        RAISE NOTICE '_new tables renamed to final names';

        -- Update golfinstancesdetails foreign key to reference final Instances
        ALTER TABLE golfinstancesdetails 
        DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

        ALTER TABLE golfinstancesdetails 
        ADD CONSTRAINT golfinstancesdetails_instanceid_fkey 
        FOREIGN KEY (instanceid) REFERENCES Instances(instanceid) ON DELETE CASCADE;

        RAISE NOTICE 'Foreign key updated to reference final Instances table';
    ELSE
        RAISE NOTICE 'DRY-RUN: Would perform cutover (rename tables and update FKs)';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Cutover failed: %', SQLERRM;
END $$;

UPDATE schema_migrations SET phase = 'Phase 7', status = 'completed', details = 'Cutover completed successfully'
WHERE migration_name = 'v1_to_v2';

COMMIT;

RAISE NOTICE 'Phase 7: Cutover completed successfully';
RAISE NOTICE 'IMPORTANT: Resume application writes now';

-- ============================================================================
-- Phase 8: Rollback Procedure (COMMENTED - Execute only if cutover fails)
-- ============================================================================
/*
BEGIN;

UPDATE schema_migrations SET phase = 'Phase 8', status = 'started', details = 'Rollback in progress'
WHERE migration_name = 'v1_to_v2';

DO $$
BEGIN
    -- Rename tables back
    ALTER TABLE Instances RENAME TO Instances_new_failed;
    ALTER TABLE History RENAME TO History_new_failed;
    ALTER TABLE NewEvents RENAME TO NewEvents_new_failed;
    ALTER TABLE NewTasks RENAME TO NewTasks_new_failed;

    ALTER TABLE Instances_old RENAME TO Instances;
    ALTER TABLE History_old RENAME TO History;
    ALTER TABLE NewEvents_old RENAME TO NewEvents;
    ALTER TABLE NewTasks_old RENAME TO NewTasks;

    -- Restore foreign keys to old tables
    ALTER TABLE golfinstancesdetails 
    DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

    ALTER TABLE golfinstancesdetails 
    ADD CONSTRAINT golfinstancesdetails_instanceid_fkey 
    FOREIGN KEY (instanceid) REFERENCES Instances(instanceid) ON DELETE CASCADE;

    -- Restore sequence values from persistent backup
    PERFORM setval('Instances_SequenceNumber_seq', 
        (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'Instances_SequenceNumber_seq'));
    PERFORM setval('History_SequenceNumber_seq', 
        (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'History_SequenceNumber_seq'));
    PERFORM setval('NewEvents_SequenceNumber_seq', 
        (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'NewEvents_SequenceNumber_seq'));
    PERFORM setval('NewTasks_SequenceNumber_seq', 
        (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'NewTasks_SequenceNumber_seq'));
END $$;

UPDATE schema_migrations SET phase = 'Phase 8', status = 'completed', details = 'Rollback completed'
WHERE migration_name = 'v1_to_v2';

COMMIT;

RAISE NOTICE 'Rollback completed successfully';
RAISE NOTICE 'IMPORTANT: Resume application writes now';
*/

-- ============================================================================
-- Phase 9: Cleanup (COMMENTED - Execute only after successful migration)
-- ============================================================================
/*
BEGIN;

UPDATE schema_migrations SET phase = 'Phase 9', status = 'started', details = 'Cleanup in progress'
WHERE migration_name = 'v1_to_v2';

-- Drop old tables
DROP TABLE IF EXISTS Instances_old;
DROP TABLE IF EXISTS History_old;  -- This will drop all partitions
DROP TABLE IF EXISTS NewEvents_old;  -- This will drop all partitions
DROP TABLE IF EXISTS NewTasks_old;

-- Drop old sequences
DROP SEQUENCE IF EXISTS Instances_SequenceNumber_seq;
DROP SEQUENCE IF EXISTS History_SequenceNumber_seq;
DROP SEQUENCE IF EXISTS NewEvents_SequenceNumber_seq;
DROP SEQUENCE IF EXISTS NewTasks_SequenceNumber_seq;

-- Drop persistent backup tables
DROP TABLE IF EXISTS migration_sequence_backup;
DROP TABLE IF EXISTS schema_migrations;

UPDATE schema_migrations SET phase = 'Phase 9', status = 'completed', details = 'Cleanup completed'
WHERE migration_name = 'v1_to_v2';

COMMIT;

RAISE NOTICE 'Cleanup completed successfully';
*/
