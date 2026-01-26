-- ============================================================================
-- SQL Server Data Extraction Script - Tier 2 - CORRECTED
-- Perseus Database Migration: 15% Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract 15% sample from 11 Tier 2 tables (depend on Tier 0-1)
-- Prerequisites: extract-tier0-corrected.sql AND extract-tier1-corrected.sql
-- Output: Temp tables for downstream tier extraction + CSV exports
-- Version: 2.0 (corrected counts, workflow_step logic, idempotency, error handling)
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'TIER 2 EXTRACTION - Starting (CORRECTED)';
PRINT 'Sample Rate: 15% (within valid FK set)';
PRINT 'Tables: 11 tables (depend on Tier 0-1)';
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
-- PREREQUISITE CHECK
-- ============================================================================
IF OBJECT_ID('tempdb..#temp_perseus_user') IS NULL
   OR OBJECT_ID('tempdb..#temp_workflow') IS NULL
   OR OBJECT_ID('tempdb..#temp_goo_type') IS NULL
BEGIN
    PRINT 'ERROR: Tier 1 temp tables not found!';
    PRINT 'You must run extract-tier0-corrected.sql and extract-tier1-corrected.sql first.';
    RAISERROR('Missing Tier 1 data', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0-1 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 2: TABLES WITH TIER 0-1 DEPENDENCIES
-- CRITICAL FIX: workflow_step uses scope_id → workflow.id (NOT workflow_section_id)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. feed_type
-- Dependencies: perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: feed_type';

    IF OBJECT_ID('tempdb..#temp_feed_type') IS NOT NULL
        DROP TABLE #temp_feed_type;

    WITH valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT ft.*
    INTO #temp_feed_type
    FROM dbo.feed_type ft
    WHERE ft.added_by IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: feed_type';
END CATCH;

-- ----------------------------------------------------------------------------
-- 2. goo_type_combine_component
-- Dependencies: goo_type_combine_target
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo_type_combine_component';

    IF OBJECT_ID('tempdb..#temp_goo_type_combine_component') IS NOT NULL
        DROP TABLE #temp_goo_type_combine_component;

    WITH valid_targets AS (
        SELECT id FROM #temp_goo_type_combine_target
    )
    SELECT TOP 15 PERCENT gtcc.*
    INTO #temp_goo_type_combine_component
    FROM dbo.goo_type_combine_component gtcc
    WHERE gtcc.combine_id IN (SELECT id FROM valid_targets)
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
    PRINT '  Skipping table: goo_type_combine_component';
END CATCH;

-- ----------------------------------------------------------------------------
-- 3. material_inventory_threshold
-- Dependencies: goo_type, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_inventory_threshold';

    IF OBJECT_ID('tempdb..#temp_material_inventory_threshold') IS NOT NULL
        DROP TABLE #temp_material_inventory_threshold;

    WITH valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT mit.*
    INTO #temp_material_inventory_threshold
    FROM dbo.material_inventory_threshold mit
    WHERE mit.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
      AND mit.created_by_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: material_inventory_threshold';
END CATCH;

-- ----------------------------------------------------------------------------
-- 4. material_inventory_threshold_notify_user
-- Dependencies: material_inventory_threshold, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_inventory_threshold_notify_user';

    IF OBJECT_ID('tempdb..#temp_material_inventory_threshold_notify_user') IS NOT NULL
        DROP TABLE #temp_material_inventory_threshold_notify_user;

    WITH valid_thresholds AS (
        SELECT id FROM #temp_material_inventory_threshold
    ),
    valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT mitnu.*
    INTO #temp_material_inventory_threshold_notify_user
    FROM dbo.material_inventory_threshold_notify_user mitnu
    WHERE mitnu.material_inventory_threshold_id IN (SELECT id FROM valid_thresholds)
      AND mitnu.perseus_user_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: material_inventory_threshold_notify_user';
END CATCH;

-- ----------------------------------------------------------------------------
-- 5. workflow_section
-- Dependencies: workflow
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow_section';

    IF OBJECT_ID('tempdb..#temp_workflow_section') IS NOT NULL
        DROP TABLE #temp_workflow_section;

    WITH valid_workflows AS (
        SELECT id FROM #temp_workflow
    )
    SELECT TOP 15 PERCENT ws.*
    INTO #temp_workflow_section
    FROM dbo.workflow_section ws
    WHERE ws.workflow_id IN (SELECT id FROM valid_workflows)
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
    PRINT '  Skipping table: workflow_section';
END CATCH;

-- ----------------------------------------------------------------------------
-- 6. workflow_attachment
-- Dependencies: workflow
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow_attachment';

    IF OBJECT_ID('tempdb..#temp_workflow_attachment') IS NOT NULL
        DROP TABLE #temp_workflow_attachment;

    WITH valid_workflows AS (
        SELECT id FROM #temp_workflow
    )
    SELECT TOP 15 PERCENT wa.*
    INTO #temp_workflow_attachment
    FROM dbo.workflow_attachment wa
    WHERE wa.workflow_id IN (SELECT id FROM valid_workflows)
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
    PRINT '  Skipping table: workflow_attachment';
END CATCH;

-- ----------------------------------------------------------------------------
-- 7. workflow_step - CRITICAL FIX APPLIED
-- Dependencies: workflow (scope_id), goo_type (nullable)
-- CORRECTED: Uses scope_id → workflow.id (NOT workflow_section_id!)
-- CORRECTED: Uses AND logic with OR for nullable goo_type_id
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow_step (CRITICAL FIX APPLIED)';

    IF OBJECT_ID('tempdb..#temp_workflow_step') IS NOT NULL
        DROP TABLE #temp_workflow_step;

    WITH valid_workflows AS (
        SELECT id FROM #temp_workflow
    ),
    valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    )
    SELECT TOP 15 PERCENT wstep.*
    INTO #temp_workflow_step
    FROM dbo.workflow_step wstep
    WHERE wstep.scope_id IN (SELECT id FROM valid_workflows)  -- FIXED: scope_id → workflow
      AND (wstep.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
           OR wstep.goo_type_id IS NULL)  -- FIXED: AND with OR for nullable FK
    ORDER BY NEWID();

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL FIX: scope_id → workflow.id (not workflow_section_id)';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: workflow_step';
END CATCH;

-- ----------------------------------------------------------------------------
-- 8. recipe
-- Dependencies: recipe_type, recipe_category, goo_type, feed_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: recipe';

    IF OBJECT_ID('tempdb..#temp_recipe') IS NOT NULL
        DROP TABLE #temp_recipe;

    WITH valid_types AS (
        SELECT id FROM #temp_recipe_type
    ),
    valid_categories AS (
        SELECT id FROM #temp_recipe_category
    ),
    valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    ),
    valid_feed_types AS (
        SELECT id FROM #temp_feed_type
    )
    SELECT TOP 15 PERCENT r.*
    INTO #temp_recipe
    FROM dbo.recipe r
    WHERE r.recipe_type_id IN (SELECT id FROM valid_types)
      AND r.recipe_category_id IN (SELECT id FROM valid_categories)
      AND (r.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types) OR r.goo_type_id IS NULL)
      AND (r.feed_type_id IN (SELECT id FROM valid_feed_types) OR r.feed_type_id IS NULL)
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
    PRINT '  Skipping table: recipe';
END CATCH;

-- ----------------------------------------------------------------------------
-- 9. smurf_group
-- Dependencies: perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: smurf_group';

    IF OBJECT_ID('tempdb..#temp_smurf_group') IS NOT NULL
        DROP TABLE #temp_smurf_group;

    WITH valid_users AS (
        SELECT id FROM #temp_perseus_user
    )
    SELECT TOP 15 PERCENT sg.*
    INTO #temp_smurf_group
    FROM dbo.smurf_group sg
    WHERE sg.owner_id IN (SELECT id FROM valid_users)
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
    PRINT '  Skipping table: smurf_group';
END CATCH;

-- ----------------------------------------------------------------------------
-- 10. smurf_goo_type
-- Dependencies: goo_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: smurf_goo_type';

    IF OBJECT_ID('tempdb..#temp_smurf_goo_type') IS NOT NULL
        DROP TABLE #temp_smurf_goo_type;

    WITH valid_goo_types AS (
        SELECT goo_type_id FROM #temp_goo_type
    )
    SELECT TOP 15 PERCENT sgt.*
    INTO #temp_smurf_goo_type
    FROM dbo.smurf_goo_type sgt
    WHERE sgt.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
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
    PRINT '  Skipping table: smurf_goo_type';
END CATCH;

-- ----------------------------------------------------------------------------
-- 11. property_option
-- Dependencies: property
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: property_option';

    IF OBJECT_ID('tempdb..#temp_property_option') IS NOT NULL
        DROP TABLE #temp_property_option;

    WITH valid_properties AS (
        SELECT id FROM #temp_property
    )
    SELECT TOP 15 PERCENT po.*
    INTO #temp_property_option
    FROM dbo.property_option po
    WHERE po.property_id IN (SELECT id FROM valid_properties)
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
    PRINT '  Skipping table: property_option';
END CATCH;

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'TIER 2 EXTRACTION - Complete';
PRINT '========================================';
PRINT 'Total Tables: ' + CAST(@total_tables AS VARCHAR(10));
PRINT 'Success: ' + CAST(@success_tables AS VARCHAR(10));
PRINT 'Failed: ' + CAST(@failed_tables AS VARCHAR(10));
PRINT 'Total Rows: ' + CAST(@total_rows AS VARCHAR(10));

IF @success_tables > 0
    PRINT 'Avg Rows/Table: ' + CAST(@total_rows / @success_tables AS VARCHAR(10));

PRINT '';
PRINT 'CRITICAL CORRECTIONS APPLIED:';
PRINT '  - workflow_step: scope_id → workflow.id (NOT workflow_section_id)';
PRINT '  - workflow_step: AND logic with OR for nullable goo_type_id';
PRINT '  - Table count corrected: 11 tables (was 19 in error)';
PRINT '';
PRINT 'Next: Run extract-tier3-corrected.sql';
PRINT '========================================';
GO

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. Temp tables now include Tier 0-2 data
-- 2. CRITICAL FIX: workflow_step.scope_id → workflow.id (not workflow_section_id)
-- 3. Complex FK dependencies use AND logic with OR for nullable FKs
-- 4. NULL FK values are properly handled (optional relationships)
-- 5. Script is IDEMPOTENT - can re-run if failures occur
-- 6. Error handling allows partial extraction to continue
-- ============================================================================
