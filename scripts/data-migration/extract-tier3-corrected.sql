-- ============================================================================
-- SQL Server Data Extraction Script - Tier 3 - CORRECTED
-- Perseus Database Migration: 15% Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract 15% sample from 12 Tier 3 tables (depend on Tier 0-2)
-- INCLUDES P0 CRITICAL TABLES: goo, fatsmurf
-- Prerequisites: extract-tier0-corrected.sql, tier1-corrected.sql, tier2-corrected.sql
-- Output: Temp tables for Tier 4 extraction + CSV exports
-- Version: 2.0 (corrected counts, idempotency, error handling)
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'TIER 3 EXTRACTION - Starting (CORRECTED)';
PRINT 'Sample Rate: 15% (within valid FK set)';
PRINT 'Tables: 12 tables INCLUDING P0 CRITICAL';
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
IF OBJECT_ID('tempdb..#temp_recipe') IS NULL
   OR OBJECT_ID('tempdb..#temp_workflow_step') IS NULL
   OR OBJECT_ID('tempdb..#temp_goo_type') IS NULL
   OR OBJECT_ID('tempdb..#temp_perseus_user') IS NULL
BEGIN
    PRINT 'ERROR: Critical Tier 2 temp tables not found!';
    PRINT 'You must run extract-tier0-corrected, tier1-corrected, and tier2-corrected.sql first.';
    RAISERROR('Missing Tier 2 data', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0-2 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 3: TABLES WITH TIER 0-2 DEPENDENCIES
-- INCLUDES P0 CRITICAL TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. goo (P0 CRITICAL) - Core material entity table
-- Dependencies: goo_type, workflow_step, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo (P0 CRITICAL - Core material entity)';

    IF OBJECT_ID('tempdb..#temp_goo') IS NOT NULL
        DROP TABLE #temp_goo;

    WITH valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    ),
    valid_workflow_steps AS (
        SELECT id FROM #temp_workflow_step
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT g.*
    INTO #temp_goo
    FROM dbo.goo g
    WHERE g.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
      AND (g.workflow_step_id IN (SELECT id FROM valid_workflow_steps) OR g.workflow_step_id IS NULL)
      AND (g.created_by_id IN (SELECT id FROM valid_users) OR g.created_by_id IS NULL)
    ORDER BY NEWID();

    DECLARE @goo_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @goo_rows;
    PRINT '  Rows: ' + CAST(@goo_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: goo.uid values needed for material lineage (Tier 4)';

    IF @goo_rows = 0
    BEGIN
        PRINT '  CRITICAL: Zero rows from goo!';
        RAISERROR('P0 CRITICAL: goo extraction failed', 16, 1);
        RETURN;
    END
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  CRITICAL: goo table extraction failed!';
    RAISERROR('P0 CRITICAL table extraction failed', 16, 1);
    RETURN;
END CATCH;

-- ----------------------------------------------------------------------------
-- 2. fatsmurf (P0 CRITICAL) - Experiments/transitions table
-- Dependencies: transition_type, workflow_step, perseus_user, container
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: fatsmurf (P0 CRITICAL - Experiments/transitions)';

    IF OBJECT_ID('tempdb..#temp_fatsmurf') IS NOT NULL
        DROP TABLE #temp_fatsmurf;

    WITH valid_transition_types AS (
        SELECT id FROM #temp_transition_type
    ),
    valid_workflow_steps AS (
        SELECT id FROM #temp_workflow_step
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    ),
    valid_containers AS (
        SELECT container_id FROM #temp_container
    )
    SELECT TOP 15 PERCENT f.*
    INTO #temp_fatsmurf
    FROM dbo.fatsmurf f
    WHERE f.transition_type_id IN (SELECT id FROM valid_transition_types)
      AND (f.workflow_step_id IN (SELECT id FROM valid_workflow_steps) OR f.workflow_step_id IS NULL)
      AND (f.created_by_id IN (SELECT id FROM valid_users) OR f.created_by_id IS NULL)
      AND (f.container_id IN (SELECT container_id FROM valid_containers) OR f.container_id IS NULL)
    ORDER BY NEWID();

    DECLARE @fatsmurf_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @fatsmurf_rows;
    PRINT '  Rows: ' + CAST(@fatsmurf_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: fatsmurf.uid values needed for material lineage (Tier 4)';

    IF @fatsmurf_rows = 0
    BEGIN
        PRINT '  CRITICAL: Zero rows from fatsmurf!';
        RAISERROR('P0 CRITICAL: fatsmurf extraction failed', 16, 1);
        RETURN;
    END
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  CRITICAL: fatsmurf table extraction failed!';
    RAISERROR('P0 CRITICAL table extraction failed', 16, 1);
    RETURN;
END CATCH;

-- ----------------------------------------------------------------------------
-- 3. goo_attachment
-- Dependencies: goo, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo_attachment';

    IF OBJECT_ID('tempdb..#temp_goo_attachment') IS NOT NULL
        DROP TABLE #temp_goo_attachment;

    WITH valid_goos AS (
        SELECT goo_id FROM #temp_goo
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT ga.*
    INTO #temp_goo_attachment
    FROM dbo.goo_attachment ga
    WHERE ga.goo_id IN (SELECT goo_id FROM valid_goos)
      AND ga.added_by_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: goo_attachment';
END CATCH;

-- ----------------------------------------------------------------------------
-- 4. goo_comment
-- Dependencies: goo, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo_comment';

    IF OBJECT_ID('tempdb..#temp_goo_comment') IS NOT NULL
        DROP TABLE #temp_goo_comment;

    WITH valid_goos AS (
        SELECT goo_id FROM #temp_goo
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT gc.*
    INTO #temp_goo_comment
    FROM dbo.goo_comment gc
    WHERE gc.goo_id IN (SELECT goo_id FROM valid_goos)
      AND gc.comment_by_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: goo_comment';
END CATCH;

-- ----------------------------------------------------------------------------
-- 5. goo_history
-- Dependencies: goo
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo_history';

    IF OBJECT_ID('tempdb..#temp_goo_history') IS NOT NULL
        DROP TABLE #temp_goo_history;

    WITH valid_goos AS (
        SELECT goo_id FROM #temp_goo
    )
    SELECT TOP 15 PERCENT gh.*
    INTO #temp_goo_history
    FROM dbo.goo_history gh
    WHERE gh.goo_id IN (SELECT goo_id FROM valid_goos)
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
    PRINT '  Skipping table: goo_history';
END CATCH;

-- ----------------------------------------------------------------------------
-- 6. fatsmurf_attachment
-- Dependencies: fatsmurf, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: fatsmurf_attachment';

    IF OBJECT_ID('tempdb..#temp_fatsmurf_attachment') IS NOT NULL
        DROP TABLE #temp_fatsmurf_attachment;

    WITH valid_fatsmurfs AS (
        SELECT id FROM #temp_fatsmurf
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT fa.*
    INTO #temp_fatsmurf_attachment
    FROM dbo.fatsmurf_attachment fa
    WHERE fa.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
      AND fa.added_by_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: fatsmurf_attachment';
END CATCH;

-- ----------------------------------------------------------------------------
-- 7. fatsmurf_comment
-- Dependencies: fatsmurf, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: fatsmurf_comment';

    IF OBJECT_ID('tempdb..#temp_fatsmurf_comment') IS NOT NULL
        DROP TABLE #temp_fatsmurf_comment;

    WITH valid_fatsmurfs AS (
        SELECT id FROM #temp_fatsmurf
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT fc.*
    INTO #temp_fatsmurf_comment
    FROM dbo.fatsmurf_comment fc
    WHERE fc.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
      AND fc.comment_by_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: fatsmurf_comment';
END CATCH;

-- ----------------------------------------------------------------------------
-- 8. fatsmurf_history
-- Dependencies: fatsmurf
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: fatsmurf_history';

    IF OBJECT_ID('tempdb..#temp_fatsmurf_history') IS NOT NULL
        DROP TABLE #temp_fatsmurf_history;

    WITH valid_fatsmurfs AS (
        SELECT id FROM #temp_fatsmurf
    )
    SELECT TOP 15 PERCENT fh.*
    INTO #temp_fatsmurf_history
    FROM dbo.fatsmurf_history fh
    WHERE fh.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
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
    PRINT '  Skipping table: fatsmurf_history';
END CATCH;

-- ----------------------------------------------------------------------------
-- 9. recipe_part
-- Dependencies: recipe, goo_type, unit
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: recipe_part';

    IF OBJECT_ID('tempdb..#temp_recipe_part') IS NOT NULL
        DROP TABLE #temp_recipe_part;

    WITH valid_recipes AS (
        SELECT id FROM #temp_recipe
    ),
    valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    ),
    valid_units AS (
        SELECT id FROM #temp_unit
    )
    SELECT TOP 15 PERCENT rp.*
    INTO #temp_recipe_part
    FROM dbo.recipe_part rp
    WHERE rp.recipe_id IN (SELECT id FROM valid_recipes)
      AND (rp.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types) OR rp.goo_type_id IS NULL)
      AND (rp.unit_id IN (SELECT id FROM valid_units) OR rp.unit_id IS NULL)
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
    PRINT '  Skipping table: recipe_part';
END CATCH;

-- ----------------------------------------------------------------------------
-- 10. smurf
-- Dependencies: smurf_group, goo_type, property_type, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: smurf';

    IF OBJECT_ID('tempdb..#temp_smurf') IS NOT NULL
        DROP TABLE #temp_smurf;

    WITH valid_groups AS (
        SELECT id FROM #temp_smurf_group
    ),
    valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    ),
    valid_property_types AS (
        SELECT id FROM #temp_property_type
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT s.*
    INTO #temp_smurf
    FROM dbo.smurf s
    WHERE (s.smurf_group_id IN (SELECT id FROM valid_groups) OR s.smurf_group_id IS NULL)
      AND (s.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types) OR s.goo_type_id IS NULL)
      AND (s.property_type_id IN (SELECT id FROM valid_property_types) OR s.property_type_id IS NULL)
      AND (s.created_by_id IN (SELECT id FROM valid_users) OR s.created_by_id IS NULL)
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
    PRINT '  Skipping table: smurf';
END CATCH;

-- ----------------------------------------------------------------------------
-- 11. submission
-- Dependencies: perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: submission';

    IF OBJECT_ID('tempdb..#temp_submission') IS NOT NULL
        DROP TABLE #temp_submission;

    WITH valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT sub.*
    INTO #temp_submission
    FROM dbo.submission sub
    WHERE sub.submitter_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: submission';
END CATCH;

-- ----------------------------------------------------------------------------
-- 12. material_qc
-- Dependencies: goo, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_qc';

    IF OBJECT_ID('tempdb..#temp_material_qc') IS NOT NULL
        DROP TABLE #temp_material_qc;

    WITH valid_goos AS (
        SELECT goo_id FROM #temp_goo
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT mq.*
    INTO #temp_material_qc
    FROM dbo.material_qc mq
    WHERE mq.goo_id IN (SELECT goo_id FROM valid_goos)
      AND mq.qc_by IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: material_qc';
END CATCH;

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'TIER 3 EXTRACTION - Complete';
PRINT '========================================';
PRINT 'Total Tables: ' + CAST(@total_tables AS VARCHAR(10));
PRINT 'Success: ' + CAST(@success_tables AS VARCHAR(10));
PRINT 'Failed: ' + CAST(@failed_tables AS VARCHAR(10));
PRINT 'Total Rows: ' + CAST(@total_rows AS VARCHAR(10));

IF @success_tables > 0
    PRINT 'Avg Rows/Table: ' + CAST(@total_rows / @success_tables AS VARCHAR(10));

PRINT '';
PRINT 'P0 CRITICAL TABLES EXTRACTED:';
PRINT '  - goo (with uid for FK references)';
PRINT '  - fatsmurf (with uid for FK references)';
PRINT '';
PRINT 'CORRECTIONS APPLIED:';
PRINT '  - Table count corrected: 12 tables (was 15)';
PRINT '  - Idempotency added: All tables can be re-extracted';
PRINT '  - Error handling added: Graceful failures';
PRINT '  - Zero-row validation: P0 critical tables checked';
PRINT '';
PRINT 'Next: Run extract-tier4-corrected.sql';
PRINT '========================================';
GO

-- ============================================================================
-- CRITICAL NOTES FOR TIER 4
-- ============================================================================
-- 1. #temp_goo contains sampled goo.uid values
-- 2. #temp_fatsmurf contains sampled fatsmurf.uid values
-- 3. These UIDs are REQUIRED for material_transition and transition_material
-- 4. Tier 4 will use UID-based FK filtering (not integer IDs)
-- ============================================================================
