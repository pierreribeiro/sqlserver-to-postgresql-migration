-- ============================================================================
-- SQL Server Data Extraction Script - Tier 0 (Base Tables)
-- Perseus Database Migration: 15% Sample Extraction
-- ============================================================================
-- Purpose: Extract 15% random sample from 38 Tier 0 tables (no FK dependencies)
-- Execution: Run on SQL Server (source database)
-- Output: Temp tables for downstream tier extraction + CSV exports
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'TIER 0 EXTRACTION - Starting';
PRINT 'Sample Rate: 15%';
PRINT 'Tables: 38 base tables (no dependencies)';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- TIER 0: BASE TABLES (No FK Dependencies)
-- Strategy: Random 15% sample using NEWID() for randomization
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Permissions (Order 0)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: Permissions';
SELECT TOP 15 PERCENT *
INTO #temp_Permissions
FROM dbo.Permissions
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 2. PerseusTableAndRowCounts (Order 1)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: PerseusTableAndRowCounts';
SELECT TOP 15 PERCENT *
INTO #temp_PerseusTableAndRowCounts
FROM dbo.PerseusTableAndRowCounts
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 3. Scraper (Order 2)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: Scraper';
SELECT TOP 15 PERCENT *
INTO #temp_Scraper
FROM dbo.Scraper
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 4. unit (Order 3) - P1 Critical
-- ----------------------------------------------------------------------------
PRINT 'Extracting: unit';
SELECT TOP 15 PERCENT *
INTO #temp_unit
FROM dbo.unit
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 5. recipe_category (Order 4)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: recipe_category';
SELECT TOP 15 PERCENT *
INTO #temp_recipe_category
FROM dbo.recipe_category
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 6. recipe_type (Order 5)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: recipe_type';
SELECT TOP 15 PERCENT *
INTO #temp_recipe_type
FROM dbo.recipe_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 7. run_type (Order 6)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: run_type';
SELECT TOP 15 PERCENT *
INTO #temp_run_type
FROM dbo.run_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 8. transition_type (Order 7)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: transition_type';
SELECT TOP 15 PERCENT *
INTO #temp_transition_type
FROM dbo.transition_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 9. workflow_type (Order 8)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: workflow_type';
SELECT TOP 15 PERCENT *
INTO #temp_workflow_type
FROM dbo.workflow_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 10. poll (Order 9)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: poll';
SELECT TOP 15 PERCENT *
INTO #temp_poll
FROM dbo.poll
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 11. cm_unit_dimensions (Order 10)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: cm_unit_dimensions';
SELECT TOP 15 PERCENT *
INTO #temp_cm_unit_dimensions
FROM dbo.cm_unit_dimensions
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 12. cm_user (Order 11)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: cm_user';
SELECT TOP 15 PERCENT *
INTO #temp_cm_user
FROM dbo.cm_user
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 13. cm_user_group (Order 12)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: cm_user_group';
SELECT TOP 15 PERCENT *
INTO #temp_cm_user_group
FROM dbo.cm_user_group
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 14. coa (Order 13)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: coa';
SELECT TOP 15 PERCENT *
INTO #temp_coa
FROM dbo.coa
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 15. coa_spec (Order 14)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: coa_spec';
SELECT TOP 15 PERCENT *
INTO #temp_coa_spec
FROM dbo.coa_spec
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 16. color (Order 15)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: color';
SELECT TOP 15 PERCENT *
INTO #temp_color
FROM dbo.color
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 17. container (Order 16) - P1 Critical
-- ----------------------------------------------------------------------------
PRINT 'Extracting: container';
SELECT TOP 15 PERCENT *
INTO #temp_container
FROM dbo.container
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 18. container_type (Order 18)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: container_type';
SELECT TOP 15 PERCENT *
INTO #temp_container_type
FROM dbo.container_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 19. goo_type (Order 19) - P0 CRITICAL
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_type (P0 CRITICAL)';
SELECT TOP 15 PERCENT *
INTO #temp_goo_type
FROM dbo.goo_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 20. manufacturer (Order 19)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: manufacturer';
SELECT TOP 15 PERCENT *
INTO #temp_manufacturer
FROM dbo.manufacturer
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 21. display_layout (Order 20)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: display_layout';
SELECT TOP 15 PERCENT *
INTO #temp_display_layout
FROM dbo.display_layout
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 22. display_type (Order 21)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: display_type';
SELECT TOP 15 PERCENT *
INTO #temp_display_type
FROM dbo.display_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 23. m_downstream (Order 21) - P0 CRITICAL (Performance cache)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: m_downstream (P0 CRITICAL - Performance cache)';
SELECT TOP 15 PERCENT *
INTO #temp_m_downstream
FROM dbo.m_downstream
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 24. external_goo_type (Order 22)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: external_goo_type';
SELECT TOP 15 PERCENT *
INTO #temp_external_goo_type
FROM dbo.external_goo_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 25. m_upstream (Order 23) - P0 CRITICAL (Performance cache)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: m_upstream (P0 CRITICAL - Performance cache)';
SELECT TOP 15 PERCENT *
INTO #temp_m_upstream
FROM dbo.m_upstream
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 26. m_upstream_dirty_leaves (Order 24)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: m_upstream_dirty_leaves';
SELECT TOP 15 PERCENT *
INTO #temp_m_upstream_dirty_leaves
FROM dbo.m_upstream_dirty_leaves
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 27. goo_type_property_def (Order 25)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_type_property_def';
SELECT TOP 15 PERCENT *
INTO #temp_goo_type_property_def
FROM dbo.goo_type_property_def
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 28. field_map (Order 26)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: field_map';
SELECT TOP 15 PERCENT *
INTO #temp_field_map
FROM dbo.field_map
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 29. goo_qc (Order 27)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_qc';
SELECT TOP 15 PERCENT *
INTO #temp_goo_qc
FROM dbo.goo_qc
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 30. smurf_robot (Order 28)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: smurf_robot';
SELECT TOP 15 PERCENT *
INTO #temp_smurf_robot
FROM dbo.smurf_robot
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 31. smurf_robot_part (Order 29)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: smurf_robot_part';
SELECT TOP 15 PERCENT *
INTO #temp_smurf_robot_part
FROM dbo.smurf_robot_part
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 32. property_type (Order 30)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: property_type';
SELECT TOP 15 PERCENT *
INTO #temp_property_type
FROM dbo.property_type
ORDER BY NEWID();
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 33-38. Additional Tier 0 tables
-- ----------------------------------------------------------------------------
-- NOTE: Add remaining Tier 0 tables here following same pattern
-- Check table-creation-order.md for complete list

PRINT '';
PRINT '========================================';
PRINT 'TIER 0 EXTRACTION - Complete';
PRINT 'Next: Run extract-tier1.sql';
PRINT '========================================';
GO

-- ============================================================================
-- IMPORTANT NOTES FOR EXECUTION
-- ============================================================================
-- 1. This script creates temp tables (#temp_*) that persist for the session
-- 2. Do NOT close SQL Server session - needed for Tier 1 extraction
-- 3. Export temp tables to CSV using BCP or SSMS "Export Data" wizard
-- 4. Temp tables contain sampled PKs needed for FK filtering in next tiers
-- ============================================================================
