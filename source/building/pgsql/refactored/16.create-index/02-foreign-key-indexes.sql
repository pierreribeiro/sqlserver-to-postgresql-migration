-- ============================================================================
-- File: 02-foreign-key-indexes.sql
-- Description: Foreign key indexes for optimal JOIN and CASCADE performance
-- ============================================================================
-- Migration Info:
--   Source: Table DDL FK column analysis
--   Total: Critical FK indexes not yet in table DDL
--   Purpose: Optimize JOIN performance and FK constraint enforcement
--   Analyst: Claude (Database Optimization Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard B-tree indexes
--   [✓] II. Strict Typing - Column types match table definitions
--   [✓] III. Set-Based - Indexes support set-based query optimization
--   [✓] V. Naming & Scoping - snake_case, schema-qualified
-- ============================================================================
-- Strategy:
--   FK indexes are CRITICAL for:
--   1. JOIN performance (avoid full table scans)
--   2. CASCADE operations (DELETE/UPDATE propagation)
--   3. Referential integrity checks
--
--   Priority order:
--   P0: Lineage tables (material_transition, transition_material, m_upstream, m_downstream)
--   P1: High-frequency JOINs (goo, container, fatsmurf relationships)
--   P2: Secondary FK relationships
-- ============================================================================

-- Set search path
SET search_path TO perseus, public;

-- ============================================================================
-- P0 CRITICAL: Material Lineage FK Indexes
-- ============================================================================

-- material_transition table - parent material → transition edges
CREATE INDEX idx_material_transition_material_id 
  ON perseus.material_transition (material_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_transition_material_id IS
'P0 CRITICAL: FK index on material_id (references goo.uid).
Essential for lineage queries finding all transitions using a material.
Supports: mcgetupstream, mcgetdownstream, translated view.';

-- transition_material table - transition → product material edges  
CREATE INDEX idx_transition_material_transition_id 
  ON perseus.transition_material (transition_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_transition_material_transition_id IS
'P0 CRITICAL: FK index on transition_id (references fatsmurf.uid).
Essential for lineage queries finding all materials produced by a transition.
Supports: mcgetupstream, mcgetdownstream, translated view.';

-- ============================================================================
-- P1: High-Frequency JOIN Indexes
-- ============================================================================

-- goo table FK indexes (if not already in DDL)
-- Note: idx_goo_container_id, idx_goo_recipe_id, idx_goo_recipe_part_id
-- already created in 01-missing-sqlserver-indexes.sql

CREATE INDEX idx_goo_goo_type_id 
  ON perseus.goo (goo_type_id)
  TABLESPACE pg_default;

CREATE INDEX idx_goo_manufacturer_id 
  ON perseus.goo (manufacturer_id)
  TABLESPACE pg_default;

CREATE INDEX idx_goo_added_by 
  ON perseus.goo (added_by)
  TABLESPACE pg_default;

CREATE INDEX idx_goo_workflow_step_id 
  ON perseus.goo (workflow_step_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_goo_type_id IS
'FK index on goo_type_id - critical for material type filtering.
High-frequency JOIN with goo_type table.';

COMMENT ON INDEX perseus.idx_goo_manufacturer_id IS
'FK index on manufacturer_id for supplier queries.';

COMMENT ON INDEX perseus.idx_goo_added_by IS
'FK index on added_by (perseus_user) for ownership queries.';

COMMENT ON INDEX perseus.idx_goo_workflow_step_id IS
'FK index on workflow_step_id for workflow status queries.';

-- fatsmurf table FK indexes
CREATE INDEX idx_fatsmurf_recipe_id 
  ON perseus.fatsmurf (recipe_id)
  TABLESPACE pg_default;

CREATE INDEX idx_fatsmurf_organization_id 
  ON perseus.fatsmurf (organization_id)
  TABLESPACE pg_default;

CREATE INDEX idx_fatsmurf_added_by 
  ON perseus.fatsmurf (added_by)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_recipe_id IS
'FK index on recipe_id for experiment recipe queries.';

COMMENT ON INDEX perseus.idx_fatsmurf_organization_id IS
'FK index on organization_id for organizational filtering.';

COMMENT ON INDEX perseus.idx_fatsmurf_added_by IS
'FK index on added_by (perseus_user) for ownership queries.';

-- container table FK indexes
-- Note: idx_container_type_id_covering already created in 01-missing-sqlserver-indexes.sql

CREATE INDEX idx_container_scope_id 
  ON perseus.container (scope_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_scope_id IS
'FK index on scope_id for nested set model queries.
Supports container hierarchy traversal.';

-- ============================================================================
-- P2: Secondary FK Indexes (Frequently Accessed)
-- ============================================================================

-- recipe table
CREATE INDEX idx_recipe_workflow_id 
  ON perseus.recipe (workflow_id)
  TABLESPACE pg_default;

CREATE INDEX idx_recipe_feed_type_id 
  ON perseus.recipe (feed_type_id)
  TABLESPACE pg_default;

-- recipe_part table
-- Note: idx_recipe_part_recipe_id, idx_recipe_part_goo_type_id already in DDL
-- Note: idx_recipe_part_unit_id created in 01-missing-sqlserver-indexes.sql

CREATE INDEX idx_recipe_part_workflow_step_id 
  ON perseus.recipe_part (workflow_step_id)
  TABLESPACE pg_default;

CREATE INDEX idx_recipe_part_part_recipe_id 
  ON perseus.recipe_part (part_recipe_id)
  TABLESPACE pg_default;

-- workflow_step table
CREATE INDEX idx_workflow_step_workflow_id 
  ON perseus.workflow_step (workflow_id)
  TABLESPACE pg_default;

-- material_inventory table
CREATE INDEX idx_material_inventory_allocation_container_id 
  ON perseus.material_inventory (allocation_container_id)
  TABLESPACE pg_default;

-- goo_attachment table
CREATE INDEX idx_goo_attachment_goo_attachment_type_id 
  ON perseus.goo_attachment (goo_attachment_type_id)
  TABLESPACE pg_default;

-- fatsmurf_attachment table
CREATE INDEX idx_fatsmurf_attachment_fatsmurf_attachment_type_id 
  ON perseus.fatsmurf_attachment (fatsmurf_attachment_type_id)
  TABLESPACE pg_default;

-- robot_log table
CREATE INDEX idx_robot_log_robot_id 
  ON perseus.robot_log (robot_id)
  TABLESPACE pg_default;

-- robot_log_container_sequence table
CREATE INDEX idx_robot_log_container_sequence_sequence_type_id 
  ON perseus.robot_log_container_sequence (sequence_type_id)
  TABLESPACE pg_default;

-- robot_log_read table
CREATE INDEX idx_robot_log_read_property_id 
  ON perseus.robot_log_read (property_id)
  TABLESPACE pg_default;

-- submission_entry table
CREATE INDEX idx_submission_entry_submitter_id 
  ON perseus.submission_entry (submitter_id)
  TABLESPACE pg_default;

-- poll table
CREATE INDEX idx_poll_property_id 
  ON perseus.poll (property_id)
  TABLESPACE pg_default;

-- smurf_property table
CREATE INDEX idx_smurf_property_property_id 
  ON perseus.smurf_property (property_id)
  TABLESPACE pg_default;

-- property_option table
CREATE INDEX idx_property_option_unit_id 
  ON perseus.property_option (unit_id)
  TABLESPACE pg_default;

-- coa table
CREATE INDEX idx_coa_submitter_id 
  ON perseus.coa (submitter_id)
  TABLESPACE pg_default;

CREATE INDEX idx_coa_material_id 
  ON perseus.coa (material_id)
  TABLESPACE pg_default;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON INDEX perseus.idx_recipe_workflow_id IS
'FK index on workflow_id for recipe workflow lookups.';

COMMENT ON INDEX perseus.idx_recipe_feed_type_id IS
'FK index on feed_type_id for recipe feed type filtering.';

COMMENT ON INDEX perseus.idx_recipe_part_workflow_step_id IS
'FK index on workflow_step_id for recipe part workflow steps.';

COMMENT ON INDEX perseus.idx_recipe_part_part_recipe_id IS
'FK index on part_recipe_id for nested recipe parts.';

COMMENT ON INDEX perseus.idx_workflow_step_workflow_id IS
'FK index on workflow_id for workflow step lookups.';

COMMENT ON INDEX perseus.idx_material_inventory_allocation_container_id IS
'FK index on allocation_container_id for container allocation queries.';

COMMENT ON INDEX perseus.idx_goo_attachment_goo_attachment_type_id IS
'FK index on goo_attachment_type_id for attachment type filtering.';

COMMENT ON INDEX perseus.idx_fatsmurf_attachment_fatsmurf_attachment_type_id IS
'FK index on fatsmurf_attachment_type_id for attachment type filtering.';

COMMENT ON INDEX perseus.idx_robot_log_robot_id IS
'FK index on robot_id for robot-specific log queries.';

COMMENT ON INDEX perseus.idx_robot_log_container_sequence_sequence_type_id IS
'FK index on sequence_type_id for sequence type lookups.';

COMMENT ON INDEX perseus.idx_robot_log_read_property_id IS
'FK index on property_id for reading property lookups.';

COMMENT ON INDEX perseus.idx_submission_entry_submitter_id IS
'FK index on submitter_id for submission tracking.';

COMMENT ON INDEX perseus.idx_poll_property_id IS
'FK index on property_id for poll property queries.';

COMMENT ON INDEX perseus.idx_smurf_property_property_id IS
'FK index on property_id for smurf property configuration.';

COMMENT ON INDEX perseus.idx_property_option_unit_id IS
'FK index on unit_id for property option unit lookups.';

COMMENT ON INDEX perseus.idx_coa_submitter_id IS
'FK index on submitter_id for COA submission tracking.';

COMMENT ON INDEX perseus.idx_coa_material_id IS
'FK index on material_id for COA material lookups.';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Count FK indexes by table
-- SELECT tablename, COUNT(*) as index_count
-- FROM pg_indexes
-- WHERE schemaname = 'perseus'
--   AND indexname LIKE 'idx_%_id' OR indexname LIKE 'uq_%_id'
-- GROUP BY tablename
-- ORDER BY index_count DESC;

-- Check index usage statistics
-- SELECT schemaname, tablename, indexname,
--        idx_scan as scans,
--        idx_tup_read as tuples_read,
--        idx_tup_fetch as tuples_fetched
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'perseus'
-- ORDER BY idx_scan DESC
-- LIMIT 50;

-- ============================================================================
-- END OF 02-foreign-key-indexes.sql
-- ============================================================================
