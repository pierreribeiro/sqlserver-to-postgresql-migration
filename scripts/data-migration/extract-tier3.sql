-- ============================================================================
-- SQL Server Data Extraction Script - Tier 3
-- Perseus Database Migration: 15% Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract 15% sample from Tier 3 tables (depend on Tier 0-2)
-- INCLUDES P0 CRITICAL TABLES: goo, fatsmurf
-- Prerequisites: extract-tier0.sql, tier1.sql, tier2.sql MUST be executed first
-- Output: Temp tables for Tier 4 extraction + CSV exports
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'TIER 3 EXTRACTION - Starting';
PRINT 'Sample Rate: 15% (within valid FK set)';
PRINT 'Tables: ~15 tables INCLUDING P0 CRITICAL';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- PREREQUISITE CHECK
-- ============================================================================
IF OBJECT_ID('tempdb..#temp_recipe') IS NULL
BEGIN
    PRINT 'ERROR: Tier 2 temp tables not found!';
    PRINT 'You must run extract-tier0, tier1, and tier2.sql first.';
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
-- Dependencies: goo_type, goo (self-reference), workflow_step, perseus_user
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo (P0 CRITICAL - Core material entity)';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
PRINT '  ** CRITICAL: goo.uid values needed for material lineage (Tier 4)';

-- ----------------------------------------------------------------------------
-- 2. fatsmurf (P0 CRITICAL) - Experiments/transitions table
-- Dependencies: transition_type, workflow_step, perseus_user, container
-- ----------------------------------------------------------------------------
PRINT 'Extracting: fatsmurf (P0 CRITICAL - Experiments/transitions)';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
PRINT '  ** CRITICAL: fatsmurf.uid values needed for material lineage (Tier 4)';

-- ----------------------------------------------------------------------------
-- 3. goo_attachment (depends on: goo, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_attachment';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 4. goo_comment (depends on: goo, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_comment';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 5. goo_history (depends on: goo)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_history';
WITH valid_goos AS (
    SELECT goo_id FROM #temp_goo
)
SELECT TOP 15 PERCENT gh.*
INTO #temp_goo_history
FROM dbo.goo_history gh
WHERE gh.goo_id IN (SELECT goo_id FROM valid_goos)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 6. fatsmurf_attachment (depends on: fatsmurf, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: fatsmurf_attachment';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 7. fatsmurf_comment (depends on: fatsmurf, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: fatsmurf_comment';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 8. fatsmurf_history (depends on: fatsmurf)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: fatsmurf_history';
WITH valid_fatsmurfs AS (
    SELECT id FROM #temp_fatsmurf
)
SELECT TOP 15 PERCENT fh.*
INTO #temp_fatsmurf_history
FROM dbo.fatsmurf_history fh
WHERE fh.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 9. recipe_part (depends on: recipe, goo_type, unit)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: recipe_part';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 10. smurf (depends on: smurf_group, goo_type, property_type, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: smurf';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 11. submission (depends on: perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: submission';
WITH valid_users AS (
    SELECT id FROM #temp_perseus_user
)
SELECT TOP 15 PERCENT sub.*
INTO #temp_submission
FROM dbo.submission sub
WHERE sub.submitter_id IN (SELECT id FROM valid_users)
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 12. material_qc (depends on: goo, perseus_user)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: material_qc';
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
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

PRINT '';
PRINT '========================================';
PRINT 'TIER 3 EXTRACTION - Complete';
PRINT 'P0 CRITICAL TABLES EXTRACTED:';
PRINT '  - goo (with uid for FK references)';
PRINT '  - fatsmurf (with uid for FK references)';
PRINT 'Next: Run extract-tier4.sql';
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
