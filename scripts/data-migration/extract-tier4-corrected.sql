-- ============================================================================
-- SQL Server Data Extraction Script - Tier 4 (FINAL TIER) - CORRECTED
-- Perseus Database Migration: 15% Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract 15% sample from 11 Tier 4 tables (highest dependencies)
-- INCLUDES P0 CRITICAL LINEAGE TABLES: material_transition, transition_material
-- Prerequisites: extract-tier0-corrected through tier3-corrected MUST be executed first
-- Output: Final temp tables + CSV exports
-- Version: 2.0 (idempotency, error handling)
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'TIER 4 EXTRACTION - Starting (FINAL TIER - CORRECTED)';
PRINT 'Sample Rate: 15% (within valid FK set)';
PRINT 'Tables: 11 tables INCLUDING P0 LINEAGE';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- ERROR COUNTERS
-- ============================================================================
DECLARE @total_tables INT = 0;
DECLARE @success_tables INT = 0;
DECLARE @failed_tables INT = 0;
DECLARE @total_rows INT = 0;

-- ============================================================================
-- PREREQUISITE CHECK (Enhanced - Multiple Critical Tables)
-- ============================================================================
IF OBJECT_ID('tempdb..#temp_goo') IS NULL
   OR OBJECT_ID('tempdb..#temp_fatsmurf') IS NULL
   OR OBJECT_ID('tempdb..#temp_container') IS NULL
   OR OBJECT_ID('tempdb..#temp_perseus_user') IS NULL
BEGIN
    PRINT 'ERROR: Tier 3 temp tables not found!';
    PRINT 'You must run extract-tier0-corrected, tier1-corrected, tier2-corrected, and tier3-corrected.sql first.';
    RAISERROR('Missing Tier 3 data (goo, fatsmurf)', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0-3 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 4: HIGHEST DEPENDENCY TABLES
-- INCLUDES P0 CRITICAL MATERIAL LINEAGE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. material_transition (P0 CRITICAL) - Parent material → Transition edges
-- Dependencies: goo.uid, fatsmurf.uid (UID-based FKs!)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_transition (P0 CRITICAL - Lineage INPUT edges)';

    IF OBJECT_ID('tempdb..#temp_material_transition') IS NOT NULL
        DROP TABLE #temp_material_transition;

    WITH valid_goo_uids AS (
        SELECT uid FROM #temp_goo WHERE uid IS NOT NULL
    ),
    valid_fatsmurf_uids AS (
        SELECT uid FROM #temp_fatsmurf WHERE uid IS NOT NULL
    )
    SELECT TOP 15 PERCENT mt.*
    INTO #temp_material_transition
    FROM dbo.material_transition mt
    WHERE mt.material_id IN (SELECT uid FROM valid_goo_uids)
      AND mt.transition_id IN (SELECT uid FROM valid_fatsmurf_uids)
    ORDER BY NEWID();

    DECLARE @mt_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @mt_rows;
    PRINT '  Rows: ' + CAST(@mt_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: Material lineage INPUT edges extracted (UID-based FK)';

    IF @mt_rows = 0
        PRINT '  WARNING: Zero rows from material_transition (check if source has data)';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: material_transition';
END CATCH;

-- ----------------------------------------------------------------------------
-- 2. transition_material (P0 CRITICAL) - Transition → Product material edges
-- Dependencies: fatsmurf.uid, goo.uid (UID-based FKs!)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: transition_material (P0 CRITICAL - Lineage OUTPUT edges)';

    IF OBJECT_ID('tempdb..#temp_transition_material') IS NOT NULL
        DROP TABLE #temp_transition_material;

    WITH valid_fatsmurf_uids AS (
        SELECT uid FROM #temp_fatsmurf WHERE uid IS NOT NULL
    ),
    valid_goo_uids AS (
        SELECT uid FROM #temp_goo WHERE uid IS NOT NULL
    )
    SELECT TOP 15 PERCENT tm.*
    INTO #temp_transition_material
    FROM dbo.transition_material tm
    WHERE tm.transition_id IN (SELECT uid FROM valid_fatsmurf_uids)
      AND tm.material_id IN (SELECT uid FROM valid_goo_uids)
    ORDER BY NEWID();

    DECLARE @tm_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @tm_rows;
    PRINT '  Rows: ' + CAST(@tm_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: Material lineage OUTPUT edges extracted (UID-based FK)';

    IF @tm_rows = 0
        PRINT '  WARNING: Zero rows from transition_material (check if source has data)';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: transition_material';
END CATCH;

-- ----------------------------------------------------------------------------
-- 3. material_inventory
-- Dependencies: goo, container, perseus_user, recipe
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_inventory';

    IF OBJECT_ID('tempdb..#temp_material_inventory') IS NOT NULL
        DROP TABLE #temp_material_inventory;

    WITH valid_goos AS (
        SELECT goo_id FROM #temp_goo
    ),
    valid_containers AS (
        SELECT container_id FROM #temp_container
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    ),
    valid_recipes AS (
        SELECT id FROM #temp_recipe
    )
    SELECT TOP 15 PERCENT mi.*
    INTO #temp_material_inventory
    FROM dbo.material_inventory mi
    WHERE mi.material_id IN (SELECT goo_id FROM valid_goos)
      AND mi.location_container_id IN (SELECT container_id FROM valid_containers)
      AND mi.created_by_id IN (SELECT id FROM valid_users)
      AND (mi.recipe_id IN (SELECT id FROM valid_recipes) OR mi.recipe_id IS NULL)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: material_inventory';
END CATCH;

-- ----------------------------------------------------------------------------
-- 4. fatsmurf_reading
-- Dependencies: fatsmurf, poll
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: fatsmurf_reading';

    IF OBJECT_ID('tempdb..#temp_fatsmurf_reading') IS NOT NULL
        DROP TABLE #temp_fatsmurf_reading;

    WITH valid_fatsmurfs AS (
        SELECT id FROM #temp_fatsmurf
    ),
    valid_polls AS (
        SELECT id FROM #temp_poll
    )
    SELECT TOP 15 PERCENT fr.*
    INTO #temp_fatsmurf_reading
    FROM dbo.fatsmurf_reading fr
    WHERE fr.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
      AND fr.poll_id IN (SELECT id FROM valid_polls)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: fatsmurf_reading';
END CATCH;

-- ----------------------------------------------------------------------------
-- 5. poll_history
-- Dependencies: poll, fatsmurf_reading
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: poll_history';

    IF OBJECT_ID('tempdb..#temp_poll_history') IS NOT NULL
        DROP TABLE #temp_poll_history;

    WITH valid_polls AS (
        SELECT id FROM #temp_poll
    ),
    valid_readings AS (
        SELECT id FROM #temp_fatsmurf_reading
    )
    SELECT TOP 15 PERCENT ph.*
    INTO #temp_poll_history
    FROM dbo.poll_history ph
    WHERE ph.poll_id IN (SELECT id FROM valid_polls)
      AND ph.fatsmurf_reading_id IN (SELECT id FROM valid_readings)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: poll_history';
END CATCH;

-- ----------------------------------------------------------------------------
-- 6. submission_entry
-- Dependencies: submission, smurf, goo, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: submission_entry';

    IF OBJECT_ID('tempdb..#temp_submission_entry') IS NOT NULL
        DROP TABLE #temp_submission_entry;

    WITH valid_submissions AS (
        SELECT id FROM #temp_submission
    ),
    valid_smurfs AS (
        SELECT id FROM #temp_smurf
    ),
    valid_goos AS (
        SELECT goo_id FROM #temp_goo
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT se.*
    INTO #temp_submission_entry
    FROM dbo.submission_entry se
    WHERE se.submission_id IN (SELECT id FROM valid_submissions)
      AND se.smurf_id IN (SELECT id FROM valid_smurfs)
      AND se.goo_id IN (SELECT goo_id FROM valid_goos)
      AND se.submitter_id IN (SELECT id FROM valid_users)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: submission_entry';
END CATCH;

-- ----------------------------------------------------------------------------
-- 7. robot_log
-- Dependencies: robot_log_type, smurf_robot, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log';

    IF OBJECT_ID('tempdb..#temp_robot_log') IS NOT NULL
        DROP TABLE #temp_robot_log;

    WITH valid_log_types AS (
        SELECT id FROM #temp_robot_log_type
    ),
    valid_robots AS (
        SELECT id FROM #temp_smurf_robot
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT rl.*
    INTO #temp_robot_log
    FROM dbo.robot_log rl
    WHERE rl.robot_log_type_id IN (SELECT id FROM valid_log_types)
      AND rl.smurf_robot_id IN (SELECT id FROM valid_robots)
      AND rl.created_by_id IN (SELECT id FROM valid_users)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log';
END CATCH;

-- ----------------------------------------------------------------------------
-- 8. robot_log_read
-- Dependencies: robot_log, goo, property
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_read';

    IF OBJECT_ID('tempdb..#temp_robot_log_read') IS NOT NULL
        DROP TABLE #temp_robot_log_read;

    WITH valid_logs AS (
        SELECT id FROM #temp_robot_log
    ),
    valid_goos AS (
        SELECT goo_id FROM #temp_goo
    ),
    valid_properties AS (
        SELECT id FROM #temp_property
    )
    SELECT TOP 15 PERCENT rlr.*
    INTO #temp_robot_log_read
    FROM dbo.robot_log_read rlr
    WHERE rlr.robot_log_id IN (SELECT id FROM valid_logs)
      AND rlr.goo_id IN (SELECT goo_id FROM valid_goos)
      AND (rlr.property_id IN (SELECT id FROM valid_properties) OR rlr.property_id IS NULL)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_read';
END CATCH;

-- ----------------------------------------------------------------------------
-- 9. robot_log_transfer
-- Dependencies: robot_log, goo (source/dest)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_transfer';

    IF OBJECT_ID('tempdb..#temp_robot_log_transfer') IS NOT NULL
        DROP TABLE #temp_robot_log_transfer;

    WITH valid_logs AS (
        SELECT id FROM #temp_robot_log
    ),
    valid_goos AS (
        SELECT goo_id FROM #temp_goo
    )
    SELECT TOP 15 PERCENT rlt.*
    INTO #temp_robot_log_transfer
    FROM dbo.robot_log_transfer rlt
    WHERE rlt.robot_log_id IN (SELECT id FROM valid_logs)
      AND (rlt.source_goo_id IN (SELECT goo_id FROM valid_goos) OR rlt.source_goo_id IS NULL)
      AND (rlt.dest_goo_id IN (SELECT goo_id FROM valid_goos) OR rlt.dest_goo_id IS NULL)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_transfer';
END CATCH;

-- ----------------------------------------------------------------------------
-- 10. robot_log_error
-- Dependencies: robot_log
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_error';

    IF OBJECT_ID('tempdb..#temp_robot_log_error') IS NOT NULL
        DROP TABLE #temp_robot_log_error;

    WITH valid_logs AS (
        SELECT id FROM #temp_robot_log
    )
    SELECT TOP 15 PERCENT rle.*
    INTO #temp_robot_log_error
    FROM dbo.robot_log_error rle
    WHERE rle.robot_log_id IN (SELECT id FROM valid_logs)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_error';
END CATCH;

-- ----------------------------------------------------------------------------
-- 11. robot_log_container_sequence
-- Dependencies: robot_log, container
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_container_sequence';

    IF OBJECT_ID('tempdb..#temp_robot_log_container_sequence') IS NOT NULL
        DROP TABLE #temp_robot_log_container_sequence;

    WITH valid_logs AS (
        SELECT id FROM #temp_robot_log
    ),
    valid_containers AS (
        SELECT container_id FROM #temp_container
    )
    SELECT TOP 15 PERCENT rlcs.*
    INTO #temp_robot_log_container_sequence
    FROM dbo.robot_log_container_sequence rlcs
    WHERE rlcs.robot_log_id IN (SELECT id FROM valid_logs)
      AND rlcs.container_id IN (SELECT container_id FROM valid_containers)
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_container_sequence';
END CATCH;

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'TIER 4 EXTRACTION - Complete (FINAL TIER)';
PRINT '========================================';
PRINT 'Total Tables: ' + CAST(@total_tables AS VARCHAR(10));
PRINT 'Success: ' + CAST(@success_tables AS VARCHAR(10));
PRINT 'Failed: ' + CAST(@failed_tables AS VARCHAR(10));
PRINT 'Total Rows: ' + CAST(@total_rows AS VARCHAR(10));

IF @success_tables > 0
    PRINT 'Avg Rows/Table: ' + CAST(@total_rows / @success_tables AS VARCHAR(10));

PRINT '';
PRINT 'P0 CRITICAL LINEAGE TABLES EXTRACTED:';
PRINT '  - material_transition (INPUT edges): ' + CAST(@mt_rows AS VARCHAR(10)) + ' rows';
PRINT '  - transition_material (OUTPUT edges): ' + CAST(@tm_rows AS VARCHAR(10)) + ' rows';
PRINT '';
PRINT 'CORRECTIONS APPLIED:';
PRINT '  - Idempotency added: All tables can be re-extracted';
PRINT '  - Error handling added: Graceful failures';
PRINT '  - UID-based FK filtering: Correct for lineage tables';
PRINT '';
PRINT '========================================';
PRINT 'ALL EXTRACTION COMPLETE!';
PRINT '========================================';
PRINT 'Next Steps:';
PRINT '  1. Export all #temp_* tables to CSV';
PRINT '  2. Run load-data.sh on PostgreSQL';
PRINT '  3. Validate referential integrity';
PRINT '========================================';
GO

-- ============================================================================
-- EXTRACTION SUMMARY - ALL TIERS
-- ============================================================================
-- Total temp tables created: 76 (all Perseus tables for 15% sample)
-- Sample rate: 15% (±2% variance due to FK filtering)
-- Referential integrity: PRESERVED (all FK relationships valid)
--
-- EXPORT INSTRUCTIONS:
-- Use BCP or SSMS "Export Data" wizard to export all #temp_* tables to CSV:
--
-- Example BCP command:
-- bcp "SELECT * FROM tempdb..#temp_goo" queryout "C:\export\goo.csv"
--   -c -t"," -r"\n" -S SERVER -U USER -P PASSWORD
--
-- Or use SSMS: Right-click database → Tasks → Export Data → Select temp tables
-- ============================================================================
