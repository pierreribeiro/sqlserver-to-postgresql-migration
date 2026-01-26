-- ============================================================================
-- SQL Server Data Extraction Script - Tier 2
-- Perseus Database Migration: 15% Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract 15% sample from Tier 2 tables (depend on Tier 0-1)
-- Prerequisites: extract-tier0.sql AND extract-tier1.sql MUST be executed first
-- Output: Temp tables for downstream tier extraction + CSV exports
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'TIER 2 EXTRACTION - Starting';
PRINT 'Sample Rate: 15% (within valid FK set)';
PRINT 'Tables: ~19 tables (depend on Tier 0-1)';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- PREREQUISITE CHECK
-- ============================================================================
IF OBJECT_ID('tempdb..#temp_perseus_user') IS NULL
BEGIN
    PRINT 'ERROR: Tier 1 temp tables not found!';
    PRINT 'You must run extract-tier0.sql and extract-tier1.sql first.';
    RAISERROR('Missing Tier 1 data', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0-1 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 2: TABLES WITH TIER 0-1 DEPENDENCIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. feed_type (depends on: perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: feed_type';
WITH valid_users AS (
    SELECT id FROM #temp_perseus_user
)
SELECT TOP 15 PERCENT ft.*
INTO #temp_feed_type
FROM dbo.feed_type ft
WHERE ft.added_by IN (SELECT id FROM valid_users)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 2. goo_type_combine_component (depends on: goo_type_combine_target)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_type_combine_component';
WITH valid_targets AS (
    SELECT id FROM #temp_goo_type_combine_target
)
SELECT TOP 15 PERCENT gtcc.*
INTO #temp_goo_type_combine_component
FROM dbo.goo_type_combine_component gtcc
WHERE gtcc.combine_id IN (SELECT id FROM valid_targets)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 3. material_inventory_threshold (depends on: goo_type, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: material_inventory_threshold';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 4. material_inventory_threshold_notify_user (depends on: material_inventory_threshold, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: material_inventory_threshold_notify_user';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 5. workflow_section (depends on: workflow)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: workflow_section';
WITH valid_workflows AS (
    SELECT id FROM #temp_workflow
)
SELECT TOP 15 PERCENT ws.*
INTO #temp_workflow_section
FROM dbo.workflow_section ws
WHERE ws.workflow_id IN (SELECT id FROM valid_workflows)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 6. workflow_attachment (depends on: workflow)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: workflow_attachment';
WITH valid_workflows AS (
    SELECT id FROM #temp_workflow
)
SELECT TOP 15 PERCENT wa.*
INTO #temp_workflow_attachment
FROM dbo.workflow_attachment wa
WHERE wa.workflow_id IN (SELECT id FROM valid_workflows)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 7. workflow_step (depends on: workflow_section, goo_type)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: workflow_step';
WITH valid_sections AS (
    SELECT id FROM #temp_workflow_section
),
valid_goo_types AS (
    SELECT goo_type_id FROM #temp_goo_type
)
SELECT TOP 15 PERCENT wstep.*
INTO #temp_workflow_step
FROM dbo.workflow_step wstep
WHERE wstep.workflow_section_id IN (SELECT id FROM valid_sections)
  OR wstep.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 8. recipe (depends on: recipe_type, recipe_category, goo_type, feed_type)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: recipe';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 9. smurf_group (depends on: perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: smurf_group';
WITH valid_users AS (
    SELECT id FROM #temp_perseus_user
)
SELECT TOP 15 PERCENT sg.*
INTO #temp_smurf_group
FROM dbo.smurf_group sg
WHERE sg.owner_id IN (SELECT id FROM valid_users)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 10. smurf_goo_type (depends on: goo_type)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: smurf_goo_type';
WITH valid_goo_types AS (
    SELECT goo_type_id FROM #temp_goo_type
)
SELECT TOP 15 PERCENT sgt.*
INTO #temp_smurf_goo_type
FROM dbo.smurf_goo_type sgt
WHERE sgt.goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 11. property_option (depends on: property)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: property_option';
WITH valid_properties AS (
    SELECT id FROM #temp_property
)
SELECT TOP 15 PERCENT po.*
INTO #temp_property_option
FROM dbo.property_option po
WHERE po.property_id IN (SELECT id FROM valid_properties)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

PRINT '';
PRINT '========================================';
PRINT 'TIER 2 EXTRACTION - Complete';
PRINT 'Next: Run extract-tier3.sql';
PRINT '========================================';
GO

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. Temp tables now include Tier 0-2 data
-- 2. Complex FK dependencies (multiple parents) use OR logic
-- 3. NULL FK values are allowed (optional relationships)
-- 4. Continue to Tier 3 extraction (extract-tier3.sql)
-- ============================================================================
