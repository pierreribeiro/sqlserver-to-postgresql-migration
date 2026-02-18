-- ============================================================================
-- File: 00-all-sqlserver-indexes-master.sql
-- Description: Master deployment file for all 36 SQL Server indexes
-- ============================================================================
-- Migration Info:
--   Source: SQL Server index definitions (9. create-index/)
--   Total: 36 indexes (37 original - 1 duplicate removed)
--   Duplicate Removed: fatsmurf.ix_fatsmurf_recipe_id (same as ix_fatsmurf_smurf_id)
--   Analyst: Claude (Database Optimization Agent)
--   Date: 2026-02-10
-- ============================================================================
-- Deployment:
--   psql -d perseus_dev -f 00-all-sqlserver-indexes-master.sql
--
-- Individual files available: 00-idx_scraper_active.sql through 35-idx_translated_composite.sql
-- ============================================================================

SET search_path TO perseus, public;

\echo '============================================================================'
\echo 'Deploying 36 SQL Server indexes to PostgreSQL'
\echo 'Duplicate removed: fatsmurf had 2 indexes on smurf_id (merged into 1)'
\echo '============================================================================'

-- ============================================================================
-- Table: scraper (1 index)
-- ============================================================================

\echo 'Creating index: idx_scraper_active...'
CREATE INDEX idx_scraper_active
  ON perseus.scraper (scrapingstatus)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_scraper_active IS
'Index on scraper active status for filtering active scrapers.
Original SQL Server: [idx_ACTIVE] ON [dbo].[Scraper] ([Active] ASC)
Column renamed: Active → scrapingstatus';

-- ============================================================================
-- Table: container (3 indexes)
-- ============================================================================

\echo 'Creating index: idx_container_scope_left_right_depth...'
CREATE INDEX idx_container_scope_left_right_depth
  ON perseus.container (scope_id, left_id, right_id, depth)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_scope_left_right_depth IS
'Composite index for nested set model hierarchy queries.
Supports efficient ancestor/descendant queries in container hierarchy.
Original SQL Server: [ix_container_scope_id_left_id_right_id_depth]';

\echo 'Creating index: idx_container_type_covering...'
CREATE INDEX idx_container_type_covering
  ON perseus.container (container_type_id)
  INCLUDE (id, mass)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_type_covering IS
'Covering index on container_type_id with included columns for index-only scans.
INCLUDE clause avoids table lookups for id and mass columns.
Original SQL Server: [ix_container_type] INCLUDE ([id], [mass]) WITH (FILLFACTOR = 70)';

\echo 'Creating index: uq_container_uid...'
CREATE UNIQUE INDEX uq_container_uid
  ON perseus.container (uid)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_container_uid IS
'Unique constraint on container UID.
Used as FK reference target from multiple tables.
Original SQL Server: [uniq_container_uid] UNIQUE WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: fatsmurf (4 indexes - 1 duplicate removed)
-- ============================================================================

\echo 'Creating index: idx_fatsmurf_themis_sample_id...'
CREATE INDEX idx_fatsmurf_themis_sample_id
  ON perseus.fatsmurf (themis_sample_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_themis_sample_id IS
'Index on Themis external system sample ID for integration queries.
Original SQL Server: [IX_themis_sample_id] WITH (FILLFACTOR = 90)';

\echo 'Creating index: idx_fatsmurf_container_id...'
CREATE INDEX idx_fatsmurf_container_id
  ON perseus.fatsmurf (container_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_container_id IS
'FK index on container_id for JOIN optimization with container table.
Original SQL Server: [ix_fatsmurf_container_id] WITH (FILLFACTOR = 90)';

\echo 'Creating index: idx_fatsmurf_smurf_id (DUPLICATE REMOVED)...'
CREATE INDEX idx_fatsmurf_smurf_id
  ON perseus.fatsmurf (smurf_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_smurf_id IS
'FK index on smurf_id (analytical method) for JOIN optimization.
Original SQL Server: [ix_fatsmurf_smurf_id] and [ix_fatsmurf_recipe_id] (duplicate removed)
Note: SQL Server had duplicate indexes on same column with different names';

\echo 'Creating index: uq_fatsmurf_uid...'
CREATE UNIQUE INDEX uq_fatsmurf_uid
  ON perseus.fatsmurf (uid)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_fatsmurf_uid IS
'Unique constraint on fatsmurf (experiment) UID.
Used as FK reference target from transition tables.
Original SQL Server: [uniq_fs_uid] UNIQUE WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: fatsmurf_history (1 index)
-- ============================================================================

\echo 'Creating index: idx_fatsmurf_history_fatsmurf_id...'
CREATE INDEX idx_fatsmurf_history_fatsmurf_id
  ON perseus.fatsmurf_history (fatsmurf_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_history_fatsmurf_id IS
'FK index on fatsmurf_id for audit trail queries.
Original SQL Server: [ix_fatsmurf_id] WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: fatsmurf_reading (1 index)
-- ============================================================================

\echo 'Creating index: idx_fatsmurf_reading_fatsmurf_id_covering...'
CREATE INDEX idx_fatsmurf_reading_fatsmurf_id_covering
  ON perseus.fatsmurf_reading (fatsmurf_id)
  INCLUDE (id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_reading_fatsmurf_id_covering IS
'Covering index for ISTD (internal standard) view queries.
INCLUDE clause avoids table lookups for id column.
Original SQL Server: [ix_fsr_for_istd_view] INCLUDE ([id]) WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: goo (6 indexes - P0 CRITICAL)
-- ============================================================================

\echo 'Creating index: idx_goo_added_on_covering...'
CREATE INDEX idx_goo_added_on_covering
  ON perseus.goo (added_on)
  INCLUDE (uid, container_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_added_on_covering IS
'Index on material creation timestamp with covering columns.
Supports time-based queries without table lookups for uid and container_id.
Original SQL Server: [ix_goo_added_on] INCLUDE ([uid], [container_id]) WITH (FILLFACTOR = 90)';

\echo 'Creating index: idx_goo_container_id...'
CREATE INDEX idx_goo_container_id
  ON perseus.goo (container_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_container_id IS
'FK index on container_id - supports JOINs and CASCADE operations.
Critical for container location queries.
Original SQL Server: [ix_goo_container_id]';

\echo 'Creating index: idx_goo_recipe_id...'
CREATE INDEX idx_goo_recipe_id
  ON perseus.goo (recipe_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_recipe_id IS
'FK index on recipe_id - supports recipe-based material queries.
Original SQL Server: [ix_goo_recipe_id] WITH (FILLFACTOR = 90)';

\echo 'Creating index: idx_goo_recipe_part_id...'
CREATE INDEX idx_goo_recipe_part_id
  ON perseus.goo (recipe_part_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_recipe_part_id IS
'FK index on recipe_part_id - supports recipe part lineage queries.
Original SQL Server: [ix_goo_recipe_part_id]';

\echo 'Creating index: uq_goo_uid (P0 CRITICAL)...'
CREATE UNIQUE INDEX uq_goo_uid
  ON perseus.goo (uid)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_goo_uid IS
'P0 CRITICAL: Unique constraint on goo (material) UID.
Used as FK reference target from transition tables and throughout system.
Original SQL Server: [uniq_goo_uid] UNIQUE WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: goo_history (1 index)
-- ============================================================================

\echo 'Creating index: idx_goo_history_goo_id...'
CREATE INDEX idx_goo_history_goo_id
  ON perseus.goo_history (goo_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_history_goo_id IS
'FK index on goo_id for audit trail queries.
Original SQL Server: [ix_goo_id] WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: history_value (1 index)
-- ============================================================================

\echo 'Creating index: idx_history_value_history_id...'
CREATE INDEX idx_history_value_history_id
  ON perseus.history_value (history_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_history_value_history_id IS
'FK index on history_id for key-value lookups.
Original SQL Server: [ix_history_id_value] WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: material_inventory_threshold (1 index)
-- ============================================================================

\echo 'Creating index: idx_material_inventory_threshold_material_type_id...'
CREATE INDEX idx_material_inventory_threshold_material_type_id
  ON perseus.material_inventory_threshold (material_type_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_inventory_threshold_material_type_id IS
'FK index on material_type_id for threshold queries by material type.
Original SQL Server: [IX_material_inventory_threshold_material_type_id]';

-- ============================================================================
-- Table: material_transition (1 index - P0 CRITICAL)
-- ============================================================================

\echo 'Creating index: idx_material_transition_transition_id (P0 CRITICAL)...'
CREATE INDEX idx_material_transition_transition_id
  ON perseus.material_transition (transition_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_transition_transition_id IS
'P0 CRITICAL INDEX: FK index on transition_id for material lineage queries.
Essential for upstream/downstream material tracking.
Supports: mcgetupstream, mcgetdownstream, translated view.
Original SQL Server: [ix_material_transition_transition_id]';

-- ============================================================================
-- Table: person (1 index)
-- ============================================================================

\echo 'Creating index: idx_person_km_session_id...'
CREATE INDEX idx_person_km_session_id
  ON perseus.person (km_session_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_person_km_session_id IS
'FK index on KM session ID for person session lookups.
Original SQL Server: [ix_person_km_session_id] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: poll_history (1 index)
-- ============================================================================

\echo 'Creating index: idx_poll_history_poll_id_covering...'
CREATE INDEX idx_poll_history_poll_id_covering
  ON perseus.poll_history (poll_id)
  INCLUDE (history_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_poll_history_poll_id_covering IS
'Covering index for poll history queries with included history_id.
INCLUDE clause avoids table lookups for history_id column.
Original SQL Server: [ix_history_id] ON poll_history(poll_id) INCLUDE(history_id) WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: recipe (1 index)
-- ============================================================================

\echo 'Creating index: idx_recipe_goo_type_id...'
CREATE INDEX idx_recipe_goo_type_id
  ON perseus.recipe (goo_type_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_goo_type_id IS
'FK index on goo_type_id for recipe lookups by material type.
Original SQL Server: [ix_recipe_goo_type_id] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: recipe_part (3 indexes)
-- ============================================================================

\echo 'Creating index: idx_recipe_part_goo_type_id...'
CREATE INDEX idx_recipe_part_goo_type_id
  ON perseus.recipe_part (goo_type_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_goo_type_id IS
'FK index on goo_type_id for recipe part lookups by material type.
Original SQL Server: [ix_recipe_part_goo_type_id] WITH (FILLFACTOR = 90)';

\echo 'Creating index: idx_recipe_part_recipe_id...'
CREATE INDEX idx_recipe_part_recipe_id
  ON perseus.recipe_part (recipe_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_recipe_id IS
'FK index on recipe_id for recipe part lookups by parent recipe.
Original SQL Server: [ix_recipe_part_recipe_id] WITH (FILLFACTOR = 90)';

\echo 'Creating index: idx_recipe_part_unit_id...'
CREATE INDEX idx_recipe_part_unit_id
  ON perseus.recipe_part (unit_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_unit_id IS
'FK index on unit_id for recipe part unit lookups.
Original SQL Server: [ix_recipe_part_unit_id] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: robot_log (1 index)
-- ============================================================================

\echo 'Creating index: idx_robot_log_robot_run_id...'
CREATE INDEX idx_robot_log_robot_run_id
  ON perseus.robot_log (robot_run_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_robot_run_id IS
'FK index on robot_run_id for robot log queries by run.
Original SQL Server: [ix_robot_log_robot_run_id] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: robot_log_container_sequence (1 index)
-- ============================================================================

\echo 'Creating index: idx_robot_log_container_sequence_container_id...'
CREATE INDEX idx_robot_log_container_sequence_container_id
  ON perseus.robot_log_container_sequence (container_id)
  WITH (fillfactor = 100)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_container_sequence_container_id IS
'FK index on container_id for container sequence tracking.
Original SQL Server: [ix_container_id] WITH (FILLFACTOR = 100)';

-- ============================================================================
-- Table: robot_log_read (1 index)
-- ============================================================================

\echo 'Creating index: idx_robot_log_read_robot_log_id...'
CREATE INDEX idx_robot_log_read_robot_log_id
  ON perseus.robot_log_read (robot_log_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_read_robot_log_id IS
'FK index on robot_log_id for robot reading lookups.
Original SQL Server: [ix_robot_log_read_robot_log_id] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: robot_log_transfer (1 index)
-- ============================================================================

\echo 'Creating index: idx_robot_log_transfer_robot_log_id...'
CREATE INDEX idx_robot_log_transfer_robot_log_id
  ON perseus.robot_log_transfer (robot_log_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_transfer_robot_log_id IS
'FK index on robot_log_id for robot transfer tracking.
Original SQL Server: [ix_robot_log_transfer_robot_log_id] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: robot_run (1 index)
-- ============================================================================

\echo 'Creating index: uq_robot_run_name...'
CREATE UNIQUE INDEX uq_robot_run_name
  ON perseus.robot_run (name)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_robot_run_name IS
'Unique constraint on robot run name.
Ensures each robot run has unique identifier.
Original SQL Server: [uniq_run_name] UNIQUE WITH (FILLFACTOR = 70)';

-- ============================================================================
-- Table: smurf_goo_type (1 index)
-- ============================================================================

\echo 'Creating index: uq_smurf_goo_type_composite...'
CREATE UNIQUE INDEX uq_smurf_goo_type_composite
  ON perseus.smurf_goo_type (smurf_id, goo_type_id, is_input)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_smurf_goo_type_composite IS
'UNIQUE constraint on smurf_goo_type combination.
Ensures one configuration per smurf/material type/input direction.
Original SQL Server: [uniq_index] UNIQUE ON (smurf_id, goo_type_id, is_input)';

-- ============================================================================
-- Table: submission (1 index)
-- ============================================================================

\echo 'Creating index: idx_submission_added_on...'
CREATE INDEX idx_submission_added_on
  ON perseus.submission (added_on)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_submission_added_on IS
'Time-based index for submission queries.
Supports date range and recent submission lookups.
Original SQL Server: [ix_submission_added_on] WITH (FILLFACTOR = 90)';

-- ============================================================================
-- Table: transition_material (1 index - P0 CRITICAL)
-- ============================================================================

\echo 'Creating index: idx_transition_material_material_id (P0 CRITICAL)...'
CREATE INDEX idx_transition_material_material_id
  ON perseus.transition_material (material_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_transition_material_material_id IS
'P0 CRITICAL INDEX: FK index on material_id for material lineage queries.
Essential for upstream/downstream material tracking.
Supports: mcgetupstream, mcgetdownstream, translated view.
Original SQL Server: [ix_transition_material_material_id]';

-- ============================================================================
-- Table: unit (1 index)
-- ============================================================================

\echo 'Creating index: uq_unit_name...'
CREATE UNIQUE INDEX uq_unit_name
  ON perseus.unit (name)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_unit_name IS
'Unique constraint on unit name.
Ensures each measurement unit has unique name.
Original SQL Server: [uix_unit_name] UNIQUE';

-- ============================================================================
-- Table: workflow_section (1 index)
-- ============================================================================

\echo 'Creating index: uq_workflow_section_starting_step_id...'
CREATE UNIQUE INDEX uq_workflow_section_starting_step_id
  ON perseus.workflow_section (starting_step_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_workflow_section_starting_step_id IS
'Unique constraint on starting_step_id.
Ensures each workflow step is starting step for at most one section.
Original SQL Server: [uniq_starting_step] UNIQUE';

-- ============================================================================
-- Table: translated (1 index - P0 CRITICAL)
-- ============================================================================

\echo 'Creating index: idx_translated_composite (P0 CRITICAL)...'
CREATE UNIQUE INDEX idx_translated_composite
  ON perseus.translated (source_material, destination_material, transition_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_translated_composite IS
'P0 CRITICAL: Composite UNIQUE index on materialized lineage view.
Supports efficient lineage traversal queries.
Original SQL Server: [ix_materialized] UNIQUE CLUSTERED WITH (FILLFACTOR = 90)
Note: SQL Server CLUSTERED → PostgreSQL regular B-tree (consider CLUSTER command)';

-- ============================================================================
-- Deployment Summary
-- ============================================================================

\echo '============================================================================'
\echo 'Index deployment complete!'
\echo 'Total indexes created: 36 (37 SQL Server originals - 1 duplicate removed)'
\echo ''
\echo 'Index breakdown:'
\echo '  - Regular B-tree: 25'
\echo '  - Unique constraints: 7'
\echo '  - Covering (INCLUDE): 4'
\echo '  - P0 Critical: 4 (goo.uid, material_transition, transition_material, translated)'
\echo ''
\echo 'Duplicate removed: fatsmurf had 2 indexes on smurf_id column'
\echo ''
\echo 'Next steps:'
\echo '  1. Verify index creation: SELECT COUNT(*) FROM pg_indexes WHERE schemaname = ''perseus'';'
\echo '  2. Check index sizes: SELECT pg_size_pretty(SUM(pg_relation_size(indexrelid))) FROM pg_stat_user_indexes WHERE schemaname = ''perseus'';'
\echo '  3. Validate query plans: EXPLAIN ANALYZE for critical queries'
\echo '  4. Consider CLUSTER command for translated table: CLUSTER perseus.translated USING idx_translated_composite;'
\echo '============================================================================'

-- ============================================================================
-- END OF 00-all-sqlserver-indexes-master.sql
-- ============================================================================
