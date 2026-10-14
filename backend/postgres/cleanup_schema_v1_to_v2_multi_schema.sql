-- ========================================
-- Multi-Schema Cleanup: v1 to v2 Migration
-- ========================================
-- This script cleans up old artifacts after successful migration
-- from the old schema (schema_v1.sql) to the new partitioned schema.
--
-- PREREQUISITES:
-- - Migration must have completed successfully (Phase 7)
-- - Application must be running successfully on new schema
-- - Database user must have DROP privileges on all schemas
-- - Application writes should be stopped during cleanup (optional but recommended)
--
-- ESTIMATED DOWNTIME:
-- - Cleanup: 1-2 minutes per schema (no downtime if application not writing to _v1 tables)
--
-- INSTRUCTIONS:
-- 1. Set dry_run to false for actual cleanup, true for validation only
-- 2. Run the script - it will process all schemas in the list
-- 3. The script will verify migration completed before proceeding
-- 4. WARNING: This operation is IRREVERSIBLE - all _v1 artifacts will be dropped
-- 5. After successful cleanup, resume application writes (if stopped)
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
    dry_run BOOLEAN := false;  -- Set to true for dry-run mode, false for actual cleanup
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
    old_suffix_tables_exist BOOLEAN;
    migration_table_exists BOOLEAN;
    migration_completed BOOLEAN;
    migration_cleanup_completed BOOLEAN;
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
            RAISE NOTICE 'Starting cleanup for schema: %', current_schema_name;
            RAISE NOTICE '==============================';

            -- Check dry-run mode
            IF dry_run THEN
                RAISE NOTICE 'DRY-RUN MODE: No changes will be made. This is for validation only.';
            ELSE
                RAISE NOTICE 'LIVE MODE: Changes will be made to the database.';
                RAISE NOTICE 'WARNING: This operation is IRREVERSIBLE!';
            END IF;

            -- ========================================
            -- Pre-cleanup Checks
            -- ========================================
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

            -- Check if migration already completed
            IF migration_table_exists THEN
                SELECT EXISTS (
                    SELECT 1 FROM schema_migrations
                    WHERE migration_name = 'v1_to_v2'
                    AND phase = 'Phase 7'
                    AND status = 'completed'
                ) INTO migration_completed;

                SELECT EXISTS (
                    SELECT 1 FROM schema_migrations
                    WHERE migration_name = 'v1_to_v2'
                    AND phase = 'Phase 9'
                    AND status = 'completed'
                ) INTO migration_cleanup_completed;
            ELSE
                migration_completed := false;
                migration_cleanup_completed := false;
            END IF;

            -- Cleanup already completed
            IF migration_cleanup_completed THEN
                RAISE NOTICE 'SKIPPED: Cleanup already completed for schema %. Found v1_to_v2 migration with Phase 9 completed status.', current_schema_name;
                skipped_schemas := array_append(skipped_schemas, current_schema_name);
                CONTINUE;
            END IF;

            -- Migration not completed
            IF NOT migration_completed THEN
                RAISE NOTICE 'SKIPPED: Migration not completed for schema %. Cannot perform cleanup. Run migration Phase 7 first.', current_schema_name;
                skipped_schemas := array_append(skipped_schemas, current_schema_name);
                CONTINUE;
            END IF;

            -- _v1 tables not found (nothing to cleanup)
            IF NOT old_suffix_tables_exist THEN
                RAISE NOTICE 'SKIPPED: No _v1 tables found for schema %. Nothing to cleanup.', current_schema_name;
                skipped_schemas := array_append(skipped_schemas, current_schema_name);
                CONTINUE;
            END IF;

            RAISE NOTICE 'Pre-cleanup checks passed. Migration completed and _v1 tables exist.';

            -- ========================================
            -- Cleanup Operations
            -- ========================================

            IF NOT dry_run THEN
                -- Drop _v1 tables
                DROP TABLE IF EXISTS instances_v1 CASCADE;
                DROP TABLE IF EXISTS history_v1 CASCADE;
                DROP TABLE IF EXISTS newevents_v1 CASCADE;
                DROP TABLE IF EXISTS newtasks_v1 CASCADE;

                RAISE NOTICE 'Dropped _v1 tables';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would drop _v1 tables';
            END IF;

            IF NOT dry_run THEN
                -- Drop _v1 sequences
                BEGIN
                    DROP SEQUENCE IF EXISTS instances_sequencenumber_seq_v1 CASCADE;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Sequence instances_sequencenumber_seq_v1 does not exist or could not be dropped.';
                END;
                BEGIN
                    DROP SEQUENCE IF EXISTS history_sequencenumber_seq_v1 CASCADE;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Sequence history_sequencenumber_seq_v1 does not exist or could not be dropped.';
                END;
                BEGIN
                    DROP SEQUENCE IF EXISTS newevents_sequencenumber_seq_v1 CASCADE;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Sequence newevents_sequencenumber_seq_v1 does not exist or could not be dropped.';
                END;
                BEGIN
                    DROP SEQUENCE IF EXISTS newtasks_sequencenumber_seq_v1 CASCADE;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Sequence newtasks_sequencenumber_seq_v1 does not exist or could not be dropped.';
                END;

                RAISE NOTICE 'Dropped _v1 sequences';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would drop _v1 sequences';
            END IF;

            IF NOT dry_run THEN
                -- Drop _v1 indexes
                BEGIN
                    DROP INDEX IF EXISTS IX_Instances_ParentInstanceID_v1 CASCADE;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Index IX_Instances_ParentInstanceID_v1 does not exist or could not be dropped.';
                END;
                BEGIN
                    DROP INDEX IF EXISTS IX_Instances_RuntimeStatus_NonTerminal_v1 CASCADE;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Index IX_Instances_RuntimeStatus_NonTerminal_v1 does not exist or could not be dropped.';
                END;

                RAISE NOTICE 'Dropped _v1 indexes';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would drop _v1 indexes';
            END IF;

            IF NOT dry_run THEN
                -- Drop migration_sequence_backup table
                DROP TABLE IF EXISTS migration_sequence_backup CASCADE;

                RAISE NOTICE 'Dropped migration_sequence_backup table';
            ELSE
                RAISE NOTICE 'DRY-RUN: Would drop migration_sequence_backup table';
            END IF;

            IF NOT dry_run THEN
                -- Update schema_migrations table to mark cleanup as completed
                IF migration_table_exists THEN
                    UPDATE schema_migrations
                    SET phase = 'Phase 9',
                        status = 'completed',
                        executed_at = NOW(),
                        details = 'Cleanup completed: _v1 tables, sequences, indexes, and backup table dropped'
                    WHERE migration_name = 'v1_to_v2';

                    RAISE NOTICE 'Updated schema_migrations table with cleanup status';
                END IF;
            ELSE
                RAISE NOTICE 'DRY-RUN: Would update schema_migrations table with cleanup status';
            END IF;

            success_count := success_count + 1;
            RAISE NOTICE '==============================';
            RAISE NOTICE 'Cleanup completed successfully for schema: %', current_schema_name;
            RAISE NOTICE '==============================';

        EXCEPTION WHEN OTHERS THEN
            failed_schemas := array_append(failed_schemas, current_schema_name);
            error_message := SQLERRM;
            RAISE WARNING 'Cleanup failed for schema %: %', current_schema_name, error_message;

            -- Restore search path on error
            PERFORM set_config('search_path', 'public', false);
        END;
    END LOOP;

    -- Restore default search path
    PERFORM set_config('search_path', 'public', false);

    -- Report results
    RAISE NOTICE '==============================';
    RAISE NOTICE 'MULTI-SCHEMA CLEANUP SUMMARY';
    RAISE NOTICE '==============================';
    RAISE NOTICE 'Total schemas processed: %', COALESCE(array_length(schemas, 1), 0);
    RAISE NOTICE 'Successful cleanups: %', success_count;
    RAISE NOTICE 'Skipped cleanups: %', COALESCE(array_length(skipped_schemas, 1), 0);
    RAISE NOTICE 'Failed cleanups: %', COALESCE(array_length(failed_schemas, 1), 0);
    IF array_length(skipped_schemas, 1) > 0 THEN
        RAISE NOTICE 'Skipped schemas: %', array_to_string(skipped_schemas, ', ');
    END IF;
    IF array_length(failed_schemas, 1) > 0 THEN
        RAISE NOTICE 'Failed schemas: %', array_to_string(failed_schemas, ', ');
    END IF;
    RAISE NOTICE '==============================';

    IF array_length(failed_schemas, 1) > 0 THEN
        RAISE WARNING 'Some schemas failed to cleanup. Please review the errors above.';
    ELSE
        RAISE NOTICE 'All schemas processed successfully!';
    END IF;
END $$;
