-- ========================================
-- Multi-Schema Rollback: v1 to v2 Migration
-- ========================================
-- This script rolls back the migration from the new partitioned schema
-- back to the old schema (schema_v1.sql) for multiple schemas.
--
-- PREREQUISITES:
-- - Database user must have CREATE, ALTER, DROP privileges on all schemas
-- - Application writes should be stopped during rollback
--
-- ESTIMATED DOWNTIME:
-- - Rollback: 5-10 minutes per schema (stop writes, rename tables, restore sequences)
--
-- INSTRUCTIONS:
-- 1. Set dry_run to false for actual rollback, true for validation only
-- 2. Run the script - it will process all schemas in the list
-- 3. The script automatically detects rollback scenario:
--    - Before cutover: Drops _v2 tables, restores sequences
--    - After cutover: Swaps table names back, restores sequences
-- 4. After successful rollback, resume application writes
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
    dry_run BOOLEAN := false;  -- Set to true for dry-run mode, false for actual rollback
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

    -- Variables for state detection
    old_tables_exist BOOLEAN;
    new_tables_exist BOOLEAN;
    old_suffix_tables_exist BOOLEAN;
    migration_table_exists BOOLEAN;
    migration_phase TEXT;
    rollback_scenario TEXT;  -- 'before_cutover' or 'after_cutover'
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
            RAISE NOTICE 'Starting rollback for schema: %', current_schema_name;
            RAISE NOTICE '==============================';

            -- Check dry-run mode
            IF dry_run THEN
                RAISE NOTICE 'DRY-RUN MODE: No changes will be made. This is for validation only.';
            ELSE
                RAISE NOTICE 'LIVE MODE: Changes will be made to the database.';
            END IF;

            -- ========================================
            -- State Detection
            -- ========================================
            -- Check if old tables exist (instances, history, newevents, newtasks)
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'instances'
                AND table_schema = current_schema()
            ) INTO old_tables_exist;

            -- Check if _v2 tables exist (migration in progress)
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'instances_v2'
                AND table_schema = current_schema()
            ) INTO new_tables_exist;

            -- Check if _v1 tables exist (migration completed)
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

            -- Get migration phase if table exists
            IF migration_table_exists THEN
                SELECT phase INTO migration_phase
                FROM schema_migrations
                WHERE migration_name = 'v1_to_v2';
            ELSE
                migration_phase := NULL;
            END IF;

            -- Determine rollback scenario
            IF new_tables_exist AND old_tables_exist THEN
                -- Migration in progress (before cutover)
                rollback_scenario := 'before_cutover';
                RAISE NOTICE 'DETECTED: Rollback scenario - BEFORE CUTOVER (migration in progress)';
            ELSIF old_suffix_tables_exist AND NOT new_tables_exist THEN
                -- Migration completed (after cutover)
                rollback_scenario := 'after_cutover';
                RAISE NOTICE 'DETECTED: Rollback scenario - AFTER CUTOVER (migration completed)';
            ELSIF old_tables_exist AND NOT new_tables_exist AND NOT old_suffix_tables_exist THEN
                -- Already on old schema (no migration to rollback)
                RAISE NOTICE 'SKIPPED: Schema % is already on old schema. No migration to rollback.', current_schema_name;
                skipped_schemas := array_append(skipped_schemas, current_schema_name);
                CONTINUE;
            ELSE
                RAISE EXCEPTION 'Cannot determine rollback state for schema %. Unexpected table configuration.', current_schema_name;
            END IF;

            -- ========================================
            -- Rollback: Before Cutover Scenario
            -- ========================================
            IF rollback_scenario = 'before_cutover' THEN
                RAISE NOTICE 'Starting rollback for BEFORE CUTOVER scenario';

                IF NOT dry_run THEN
                    -- Drop _v2 tables and partitions
                    -- Drop instances_v2
                    DROP TABLE IF EXISTS instances_v2 CASCADE;

                    -- Drop history_v2 and all partitions
                    DROP TABLE IF EXISTS history_v2 CASCADE;
                    FOR i IN 0..127 LOOP
                        EXECUTE format('DROP TABLE IF EXISTS history_v2_%s CASCADE', lpad(i::text, 4, '0'));
                    END LOOP;

                    -- Drop newevents_v2 and all partitions
                    DROP TABLE IF EXISTS newevents_v2 CASCADE;
                    FOR i IN 0..127 LOOP
                        EXECUTE format('DROP TABLE IF EXISTS newevents_v2_%s CASCADE', lpad(i::text, 4, '0'));
                    END LOOP;

                    -- Drop newtasks_v2
                    DROP TABLE IF EXISTS newtasks_v2 CASCADE;

                    RAISE NOTICE 'Dropped all _v2 tables and partitions';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would drop all _v2 tables and partitions';
                END IF;

                IF NOT dry_run THEN
                    -- Restore sequences from backup
                    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_sequence_backup' AND table_schema = current_schema()) THEN
                        PERFORM setval('instances_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'instances_sequencenumber_seq'));
                        PERFORM setval('history_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'history_sequencenumber_seq'));
                        PERFORM setval('newevents_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'newevents_sequencenumber_seq'));
                        PERFORM setval('newtasks_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'newtasks_sequencenumber_seq'));

                        RAISE NOTICE 'Restored sequences from backup';
                    ELSE
                        RAISE WARNING 'migration_sequence_backup table not found. Sequence restoration skipped.';
                    END IF;
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would restore sequences from backup';
                END IF;

                IF NOT dry_run THEN
                    -- Reset external FKs to reference old tables
                    ALTER TABLE golfinstancesdetails
                    DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

                    ALTER TABLE golfinstancesdetails
                    ADD CONSTRAINT golfinstancesdetails_instanceid_fkey
                    FOREIGN KEY (instanceid) REFERENCES instances(instanceid) ON DELETE CASCADE;

                    RAISE NOTICE 'Reset external FKs to reference old tables';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would reset external FKs to reference old tables';
                END IF;

                IF NOT dry_run THEN
                    -- Drop migration tracking tables
                    DROP TABLE IF EXISTS migration_sequence_backup CASCADE;
                    DROP TABLE IF EXISTS schema_migrations CASCADE;

                    RAISE NOTICE 'Dropped migration tracking tables';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would drop migration tracking tables';
                END IF;

                RAISE NOTICE 'Rollback BEFORE CUTOVER completed for schema: %', current_schema_name;

            -- ========================================
            -- Rollback: After Cutover Scenario
            -- ========================================
            ELSIF rollback_scenario = 'after_cutover' THEN
                RAISE NOTICE 'Starting rollback for AFTER CUTOVER scenario';

                IF NOT dry_run THEN
                    -- Rename current tables (final names) back to _v2
                    ALTER TABLE instances RENAME TO instances_v2;
                    ALTER TABLE history RENAME TO history_v2;
                    ALTER TABLE newevents RENAME TO newevents_v2;
                    ALTER TABLE newtasks RENAME TO newtasks_v2;

                    RAISE NOTICE 'Renamed current tables to _v2';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would rename current tables to _v2';
                END IF;

                IF NOT dry_run THEN
                    -- Rename _v1 tables back to final names
                    ALTER TABLE instances_v1 RENAME TO instances;
                    ALTER TABLE history_v1 RENAME TO history;
                    ALTER TABLE newevents_v1 RENAME TO newevents;
                    ALTER TABLE newtasks_v1 RENAME TO newtasks;

                    RAISE NOTICE 'Renamed _v1 tables to final names';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would rename _v1 tables to final names';
                END IF;

                IF NOT dry_run THEN
                    -- Restore sequences from backup
                    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_sequence_backup' AND table_schema = current_schema()) THEN
                        PERFORM setval('instances_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'instances_sequencenumber_seq'));
                        PERFORM setval('history_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'history_sequencenumber_seq'));
                        PERFORM setval('newevents_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'newevents_sequencenumber_seq'));
                        PERFORM setval('newtasks_sequencenumber_seq',
                            (SELECT last_value FROM migration_sequence_backup WHERE seq_name = 'newtasks_sequencenumber_seq'));

                        RAISE NOTICE 'Restored sequences from backup';
                    ELSE
                        RAISE WARNING 'migration_sequence_backup table not found. Sequence restoration skipped.';
                    END IF;
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would restore sequences from backup';
                END IF;

                IF NOT dry_run THEN
                    -- Update external FKs to reference old tables
                    ALTER TABLE golfinstancesdetails
                    DROP CONSTRAINT IF EXISTS golfinstancesdetails_instanceid_fkey;

                    ALTER TABLE golfinstancesdetails
                    ADD CONSTRAINT golfinstancesdetails_instanceid_fkey
                    FOREIGN KEY (instanceid) REFERENCES instances(instanceid) ON DELETE CASCADE;

                    RAISE NOTICE 'Updated external FKs to reference old tables';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would update external FKs to reference old tables';
                END IF;

                IF NOT dry_run THEN
                    -- Rename sequences back to original names
                    -- Rename current sequences (from _v2) to _v2 suffix
                    ALTER SEQUENCE instances_sequencenumber_seq RENAME TO instances_sequencenumber_seq_v2;
                    ALTER SEQUENCE history_sequencenumber_seq RENAME TO history_sequencenumber_seq_v2;
                    ALTER SEQUENCE newevents_sequencenumber_seq RENAME TO newevents_sequencenumber_seq_v2;
                    ALTER SEQUENCE newtasks_sequencenumber_seq RENAME TO newtasks_sequencenumber_seq_v2;

                    -- Rename _v1 sequences back to original names
                    BEGIN
                        ALTER SEQUENCE instances_sequencenumber_seq_v1 RENAME TO instances_sequencenumber_seq;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Sequence instances_sequencenumber_seq_v1 does not exist, skipping rename.';
                    END;
                    BEGIN
                        ALTER SEQUENCE history_sequencenumber_seq_v1 RENAME TO history_sequencenumber_seq;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Sequence history_sequencenumber_seq_v1 does not exist, skipping rename.';
                    END;
                    BEGIN
                        ALTER SEQUENCE newevents_sequencenumber_seq_v1 RENAME TO newevents_sequencenumber_seq;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Sequence newevents_sequencenumber_seq_v1 does not exist, skipping rename.';
                    END;
                    BEGIN
                        ALTER SEQUENCE newtasks_sequencenumber_seq_v1 RENAME TO newtasks_sequencenumber_seq;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Sequence newtasks_sequencenumber_seq_v1 does not exist, skipping rename.';
                    END;

                    RAISE NOTICE 'Renamed sequences back to original names';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would rename sequences back to original names';
                END IF;

                IF NOT dry_run THEN
                    -- Rename indexes back to original names
                    -- Rename current indexes (from _v2) to _v2 suffix
                    BEGIN
                        ALTER INDEX IX_Instances_ParentInstanceID RENAME TO IX_Instances_ParentInstanceID_v2;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Index IX_Instances_ParentInstanceID does not exist, skipping rename.';
                    END;
                    BEGIN
                        ALTER INDEX IX_Instances_RuntimeStatus_NonTerminal RENAME TO IX_Instances_RuntimeStatus_NonTerminal_v2;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Index IX_Instances_RuntimeStatus_NonTerminal does not exist, skipping rename.';
                    END;

                    -- Rename _v1 indexes back to original names
                    BEGIN
                        ALTER INDEX IX_Instances_ParentInstanceID_v1 RENAME TO IX_Instances_ParentInstanceID;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Index IX_Instances_ParentInstanceID_v1 does not exist, skipping rename.';
                    END;
                    BEGIN
                        ALTER INDEX IX_Instances_RuntimeStatus_NonTerminal_v1 RENAME TO IX_Instances_RuntimeStatus_NonTerminal;
                    EXCEPTION WHEN UNDEFINED_TABLE THEN
                        RAISE NOTICE 'Index IX_Instances_RuntimeStatus_NonTerminal_v1 does not exist, skipping rename.';
                    END;

                    RAISE NOTICE 'Renamed indexes back to original names';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would rename indexes back to original names';
                END IF;

                IF NOT dry_run THEN
                    -- Drop _v2 tables
                    DROP TABLE IF EXISTS instances_v2 CASCADE;
                    DROP TABLE IF EXISTS history_v2 CASCADE;
                    DROP TABLE IF EXISTS newevents_v2 CASCADE;
                    DROP TABLE IF EXISTS newtasks_v2 CASCADE;

                    -- Drop _v2 partitions
                    FOR i IN 0..127 LOOP
                        EXECUTE format('DROP TABLE IF EXISTS history_v2_%s CASCADE', lpad(i::text, 4, '0'));
                        EXECUTE format('DROP TABLE IF EXISTS newevents_v2_%s CASCADE', lpad(i::text, 4, '0'));
                    END LOOP;

                    RAISE NOTICE 'Dropped _v2 tables and partitions';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would drop _v2 tables and partitions';
                END IF;

                IF NOT dry_run THEN
                    -- Drop migration tracking tables
                    DROP TABLE IF EXISTS migration_sequence_backup CASCADE;
                    DROP TABLE IF EXISTS schema_migrations CASCADE;

                    RAISE NOTICE 'Dropped migration tracking tables';
                ELSE
                    RAISE NOTICE 'DRY-RUN: Would drop migration tracking tables';
                END IF;

                RAISE NOTICE 'Rollback AFTER CUTOVER completed for schema: %', current_schema_name;
            END IF;

            success_count := success_count + 1;
            RAISE NOTICE '==============================';
            RAISE NOTICE 'Rollback completed successfully for schema: %', current_schema_name;
            RAISE NOTICE '==============================';

        EXCEPTION WHEN OTHERS THEN
            failed_schemas := array_append(failed_schemas, current_schema_name);
            error_message := SQLERRM;
            RAISE WARNING 'Rollback failed for schema %: %', current_schema_name, error_message;

            -- Restore search path on error
            PERFORM set_config('search_path', 'public', false);
        END;
    END LOOP;

    -- Restore default search path
    PERFORM set_config('search_path', 'public', false);

    -- Report results
    RAISE NOTICE '==============================';
    RAISE NOTICE 'MULTI-SCHEMA ROLLBACK SUMMARY';
    RAISE NOTICE '==============================';
    RAISE NOTICE 'Total schemas processed: %', COALESCE(array_length(schemas, 1), 0);
    RAISE NOTICE 'Successful rollbacks: %', success_count;
    RAISE NOTICE 'Skipped rollbacks: %', COALESCE(array_length(skipped_schemas, 1), 0);
    RAISE NOTICE 'Failed rollbacks: %', COALESCE(array_length(failed_schemas, 1), 0);
    IF array_length(skipped_schemas, 1) > 0 THEN
        RAISE NOTICE 'Skipped schemas: %', array_to_string(skipped_schemas, ', ');
    END IF;
    IF array_length(failed_schemas, 1) > 0 THEN
        RAISE NOTICE 'Failed schemas: %', array_to_string(failed_schemas, ', ');
    END IF;
    RAISE NOTICE '==============================';

    IF array_length(failed_schemas, 1) > 0 THEN
        RAISE WARNING 'Some schemas failed to rollback. Please review the errors above.';
    ELSE
        RAISE NOTICE 'All schemas processed successfully!';
    END IF;
END $$;
