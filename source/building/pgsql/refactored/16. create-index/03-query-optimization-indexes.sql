-- ============================================================================
-- File: 03-query-optimization-indexes.sql
-- Description: Query optimization indexes based on procedure/view analysis
-- ============================================================================
-- Migration Info:
--   Source: Stored procedure query pattern analysis
--   Total: Composite, partial, and covering indexes for common query patterns
--   Purpose: Achieve ±20% performance target vs SQL Server
--   Analyst: Claude (Database Optimization Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard PostgreSQL index types
--   [✓] II. Strict Typing - Column types match table definitions
--   [✓] III. Set-Based - Indexes support set-based query optimization
--   [✓] V. Naming & Scoping - snake_case, schema-qualified
-- ============================================================================
-- Strategy:
--   Based on analysis of 15 stored procedures (mcgetupstream, mcgetdownstream,
--   GetMaterialByRunProperties, etc.), create indexes for:
--
--   1. Composite indexes for multi-column predicates
--   2. Partial indexes for common filtered queries
--   3. Covering indexes (INCLUDE) to avoid table lookups
--   4. Expression indexes for case-insensitive searches
-- ============================================================================

-- Set search path
SET search_path TO perseus, public;

-- ============================================================================
-- Material Lineage Optimization (P0 CRITICAL)
-- ============================================================================

-- goo table: UID + type composite (most common query pattern)
CREATE INDEX idx_goo_uid_type_covering 
  ON perseus.goo (uid, goo_type_id)
  INCLUDE (name, description, added_on)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_uid_type_covering IS
'P0 CRITICAL: Composite index on uid + goo_type_id with covering columns.
Supports material lookups by UID with type filtering.
Avoids table lookups for name, description, added_on.
Query pattern: WHERE uid = ? AND goo_type_id IN (...)';

-- goo table: Active materials only (partial index)
CREATE INDEX idx_goo_active_materials 
  ON perseus.goo (id, uid, goo_type_id, added_on DESC)
  WHERE is_locked = FALSE
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_active_materials IS
'Partial index for active (non-locked) materials.
Significantly smaller than full table index - only includes unlocked materials.
Query pattern: WHERE is_locked = FALSE';

-- goo table: Recent materials (partial index for time-based queries)
CREATE INDEX idx_goo_recent 
  ON perseus.goo (added_on DESC, goo_type_id)
  WHERE added_on > CURRENT_DATE - INTERVAL '90 days'
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_recent IS
'Partial index for recently added materials (last 90 days).
Supports dashboard and recent activity queries.
Query pattern: WHERE added_on > CURRENT_DATE - INTERVAL ''90 days''';

-- m_upstream: Composite for parent-child queries
CREATE INDEX idx_m_upstream_child_parent_distance 
  ON perseus.m_upstream (child_goo_id, parent_goo_id)
  INCLUDE (distance)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_m_upstream_child_parent_distance IS
'P0 CRITICAL: Composite covering index for upstream lineage queries.
Optimized for mcgetupstream procedure.
Query pattern: WHERE child_goo_id IN (...) ORDER BY distance';

-- m_upstream: Reverse direction for parent-first queries
CREATE INDEX idx_m_upstream_parent_child_distance 
  ON perseus.m_upstream (parent_goo_id, child_goo_id)
  INCLUDE (distance)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_m_upstream_parent_child_distance IS
'Composite covering index for reverse upstream queries.
Supports finding all children of a parent material.
Query pattern: WHERE parent_goo_id IN (...)';

-- m_downstream: Composite for parent-child queries
CREATE INDEX idx_m_downstream_parent_child_distance 
  ON perseus.m_downstream (parent_goo_id, child_goo_id)
  INCLUDE (distance)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_m_downstream_parent_child_distance IS
'P0 CRITICAL: Composite covering index for downstream lineage queries.
Optimized for mcgetdownstream procedure.
Query pattern: WHERE parent_goo_id IN (...) ORDER BY distance';

-- m_downstream: Reverse direction for child-first queries
CREATE INDEX idx_m_downstream_child_parent_distance 
  ON perseus.m_downstream (child_goo_id, parent_goo_id)
  INCLUDE (distance)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_m_downstream_child_parent_distance IS
'Composite covering index for reverse downstream queries.
Supports finding all parents of a child material.
Query pattern: WHERE child_goo_id IN (...)';

-- ============================================================================
-- Container Tracking Optimization
-- ============================================================================

-- container table: UID + type composite
CREATE INDEX idx_container_uid_type_covering 
  ON perseus.container (uid, container_type_id)
  INCLUDE (name, label)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_uid_type_covering IS
'Composite covering index for container lookups.
Supports container queries by UID with type filtering.
Query pattern: WHERE uid = ? AND container_type_id = ?';

-- container table: Nested set left boundary index
CREATE INDEX idx_container_nested_set_left 
  ON perseus.container (left_id, right_id, scope_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_nested_set_left IS
'Composite index for nested set model LEFT boundary queries.
Optimized for ancestor/descendant queries.
Query pattern: WHERE left_id BETWEEN ? AND ? AND scope_id = ?';

-- container table: Active containers (partial index)
CREATE INDEX idx_container_active 
  ON perseus.container (id, uid, container_type_id)
  WHERE is_locked = FALSE
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_active IS
'Partial index for active (non-locked) containers.
Query pattern: WHERE is_locked = FALSE';

-- ============================================================================
-- Experiment/Analytical Data Optimization (fatsmurf)
-- ============================================================================

-- fatsmurf table: UID + smurf_id composite
CREATE INDEX idx_fatsmurf_uid_smurf_covering 
  ON perseus.fatsmurf (uid, smurf_id)
  INCLUDE (name, added_on)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_uid_smurf_covering IS
'Composite covering index for experiment lookups by UID and method.
Query pattern: WHERE uid = ? AND smurf_id = ?';

-- fatsmurf table: Recent experiments (partial index)
CREATE INDEX idx_fatsmurf_recent 
  ON perseus.fatsmurf (added_on DESC, smurf_id)
  WHERE added_on > CURRENT_DATE - INTERVAL '90 days'
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_recent IS
'Partial index for recently added experiments (last 90 days).
Query pattern: WHERE added_on > CURRENT_DATE - INTERVAL ''90 days''';

-- fatsmurf_reading table: Composite for analytical data queries
CREATE INDEX idx_fatsmurf_reading_composite 
  ON perseus.fatsmurf_reading (fatsmurf_id, reading_type, reading_timestamp DESC)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_reading_composite IS
'Composite index for analytical reading queries.
Supports efficient filtering by experiment, reading type, and time range.
Query pattern: WHERE fatsmurf_id = ? AND reading_type = ? ORDER BY reading_timestamp DESC';

-- ============================================================================
-- Audit Trail Optimization (history tables)
-- ============================================================================

-- goo_history table: Composite for entity history queries
CREATE INDEX idx_goo_history_entity_time 
  ON perseus.goo_history (goo_id, history_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_history_entity_time IS
'Composite index for material history queries.
Supports efficient retrieval of history events for a material.
Query pattern: WHERE goo_id = ? ORDER BY history_id DESC';

-- fatsmurf_history table: Composite for entity history queries
CREATE INDEX idx_fatsmurf_history_entity_time 
  ON perseus.fatsmurf_history (fatsmurf_id, history_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_history_entity_time IS
'Composite index for experiment history queries.
Query pattern: WHERE fatsmurf_id = ? ORDER BY history_id DESC';

-- history_value table: Composite for key-value lookups
CREATE INDEX idx_history_value_composite 
  ON perseus.history_value (history_id, key)
  INCLUDE (value)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_history_value_composite IS
'Composite covering index for history attribute lookups.
Supports key-value queries without table lookups.
Query pattern: WHERE history_id = ? AND key = ?';

-- ============================================================================
-- Search and Filter Optimization
-- ============================================================================

-- goo table: Case-insensitive name search (expression index)
CREATE INDEX idx_goo_name_lower 
  ON perseus.goo (LOWER(name))
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_name_lower IS
'Expression index for case-insensitive material name searches.
Query pattern: WHERE LOWER(name) LIKE LOWER(?)';

-- goo table: UID prefix search (for autocomplete)
CREATE INDEX idx_goo_uid_prefix 
  ON perseus.goo (uid varchar_pattern_ops)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_uid_prefix IS
'Text pattern index for UID prefix searches (autocomplete).
Supports LIKE ''prefix%'' queries efficiently.
Query pattern: WHERE uid LIKE ''M%''';

-- container table: Case-insensitive name search
CREATE INDEX idx_container_name_lower 
  ON perseus.container (LOWER(name))
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_name_lower IS
'Expression index for case-insensitive container name searches.
Query pattern: WHERE LOWER(name) LIKE LOWER(?)';

-- fatsmurf table: Case-insensitive name search
CREATE INDEX idx_fatsmurf_name_lower 
  ON perseus.fatsmurf (LOWER(name))
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_name_lower IS
'Expression index for case-insensitive experiment name searches.
Query pattern: WHERE LOWER(name) LIKE LOWER(?)';

-- perseus_user table: Case-insensitive email search
CREATE INDEX idx_perseus_user_mail_lower 
  ON perseus.perseus_user (LOWER(mail))
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_perseus_user_mail_lower IS
'Expression index for case-insensitive email searches.
Query pattern: WHERE LOWER(mail) = LOWER(?)';

-- ============================================================================
-- Recipe and Workflow Optimization
-- ============================================================================

-- recipe table: Composite for goo_type + workflow queries
CREATE INDEX idx_recipe_type_workflow 
  ON perseus.recipe (goo_type_id, workflow_id)
  INCLUDE (name)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_type_workflow IS
'Composite covering index for recipe lookups by material type and workflow.
Query pattern: WHERE goo_type_id = ? AND workflow_id = ?';

-- recipe_part table: Composite for recipe + goo_type queries
CREATE INDEX idx_recipe_part_recipe_type 
  ON perseus.recipe_part (recipe_id, goo_type_id)
  INCLUDE (quantity, unit_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_recipe_type IS
'Composite covering index for recipe part lookups.
Query pattern: WHERE recipe_id = ? AND goo_type_id = ?';

-- workflow_step table: Composite for workflow hierarchy
CREATE INDEX idx_workflow_step_parent_class 
  ON perseus.workflow_step (parent_id, class_id)
  INCLUDE (step_order)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_workflow_step_parent_class IS
'Composite covering index for workflow step hierarchy queries.
Query pattern: WHERE parent_id = ? AND class_id = ? ORDER BY step_order';

-- ============================================================================
-- Robot Log Optimization
-- ============================================================================

-- robot_log table: Composite for run + timestamp queries
CREATE INDEX idx_robot_log_run_time 
  ON perseus.robot_log (robot_run_id, created_on DESC)
  INCLUDE (robot_log_type_id, class_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_run_time IS
'Composite covering index for robot log queries by run and time.
Query pattern: WHERE robot_run_id = ? ORDER BY created_on DESC';

-- robot_log_read table: Composite for log + goo queries
CREATE INDEX idx_robot_log_read_composite 
  ON perseus.robot_log_read (robot_log_id, goo_id)
  INCLUDE (property_id, raw_value)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_read_composite IS
'Composite covering index for robot reading lookups.
Query pattern: WHERE robot_log_id = ? AND goo_id = ?';

-- robot_log_transfer table: Composite for transfer tracking
CREATE INDEX idx_robot_log_transfer_composite 
  ON perseus.robot_log_transfer (robot_log_id, source_goo_id, dest_goo_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_transfer_composite IS
'Composite index for robot transfer tracking.
Query pattern: WHERE robot_log_id = ? AND (source_goo_id = ? OR dest_goo_id = ?)';

-- ============================================================================
-- Submission and QC Optimization
-- ============================================================================

-- submission table: Time-based with submitter
CREATE INDEX idx_submission_time_submitter 
  ON perseus.submission (added_on DESC, submitter_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_submission_time_submitter IS
'Composite index for submission queries by time and submitter.
Query pattern: WHERE added_on BETWEEN ? AND ? AND submitter_id = ?';

-- submission_entry table: Composite for submission + smurf
CREATE INDEX idx_submission_entry_composite 
  ON perseus.submission_entry (submission_id, smurf_id)
  INCLUDE (goo_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_submission_entry_composite IS
'Composite covering index for submission entry lookups.
Query pattern: WHERE submission_id = ? AND smurf_id = ?';

-- material_qc table: Time-based QC queries
CREATE INDEX idx_material_qc_time_material 
  ON perseus.material_qc (qc_date DESC, goo_id)
  INCLUDE (qc_by, result)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_qc_time_material IS
'Composite covering index for QC queries by date and material.
Query pattern: WHERE qc_date BETWEEN ? AND ? AND goo_id = ?';

-- coa table: Material + submission composite
CREATE INDEX idx_coa_material_submitter 
  ON perseus.coa (material_id, submitter_id)
  INCLUDE (added_on)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_coa_material_submitter IS
'Composite covering index for COA lookups by material and submitter.
Query pattern: WHERE material_id = ? AND submitter_id = ?';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Count all indexes by type
-- SELECT 
--   CASE 
--     WHEN indexdef LIKE '%INCLUDE%' THEN 'Covering Index'
--     WHEN indexdef LIKE '%WHERE%' THEN 'Partial Index'
--     WHEN indexdef LIKE '%LOWER%' THEN 'Expression Index'
--     WHEN indexdef LIKE '%UNIQUE%' THEN 'Unique Index'
--     ELSE 'Regular Index'
--   END AS index_type,
--   COUNT(*) as count
-- FROM pg_indexes
-- WHERE schemaname = 'perseus'
-- GROUP BY index_type
-- ORDER BY count DESC;

-- Find largest indexes
-- SELECT schemaname, tablename, indexname,
--        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
--        idx_scan as scans
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'perseus'
-- ORDER BY pg_relation_size(indexrelid) DESC
-- LIMIT 30;

-- Check index usage statistics
-- SELECT schemaname, tablename, indexname,
--        idx_scan as scans,
--        idx_tup_read as tuples_read,
--        idx_tup_fetch as tuples_fetched,
--        CASE 
--          WHEN idx_scan = 0 THEN 'UNUSED'
--          WHEN idx_scan < 100 THEN 'LOW USAGE'
--          ELSE 'ACTIVE'
--        END AS usage_status
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'perseus'
-- ORDER BY idx_scan DESC;

-- ============================================================================
-- END OF 03-query-optimization-indexes.sql
-- ============================================================================
