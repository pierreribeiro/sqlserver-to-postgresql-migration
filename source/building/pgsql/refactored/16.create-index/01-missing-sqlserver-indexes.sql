-- ============================================================================
-- File: 01-missing-sqlserver-indexes.sql
-- Description: SQL Server indexes not yet created in table DDL
-- ============================================================================
-- Migration Info:
--   Source: SQL Server index definitions (9. create-index/)
--   Total: 15 missing indexes from SQL Server original definitions
--   Status: These were defined in SQL Server but not yet added to PostgreSQL DDL
--   Analyst: Claude (Database Optimization Agent)
--   Date: 2026-01-26
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Standard B-tree indexes
--   [✓] II. Strict Typing - Column types match table definitions
--   [✓] III. Set-Based - Indexes support set-based query optimization
--   [✓] V. Naming & Scoping - snake_case, schema-qualified
-- ============================================================================

-- Set search path
SET search_path TO perseus, public;

-- ============================================================================
-- Table: scraper
-- ============================================================================

CREATE INDEX idx_scraper_active 
  ON perseus.scraper (scrapingstatus)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_scraper_active IS
'Index on scraper active status for filtering active scrapers.
Original: Scraper.idx_ACTIVE';

-- ============================================================================
-- Table: container
-- ============================================================================

-- Composite index for nested set model queries
CREATE INDEX idx_container_scope_left_right_depth 
  ON perseus.container (scope_id, left_id, right_id, depth)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_scope_left_right_depth IS
'Composite index for nested set model hierarchy queries.
Supports efficient ancestor/descendant queries in container hierarchy.
Original: container.ix_container_scope_id_left_id_right_id_depth';

-- Index with INCLUDE for covering index optimization
CREATE INDEX idx_container_type_id_covering 
  ON perseus.container (container_type_id)
  INCLUDE (id, mass)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_type_id_covering IS
'Covering index on container_type_id with included columns for index-only scans.
INCLUDE clause avoids table lookups for id and mass columns.
Original: container.ix_container_type with INCLUDE';

-- ============================================================================
-- Table: goo (Core material table)
-- ============================================================================

-- Time-based index with INCLUDE
CREATE INDEX idx_goo_added_on_covering 
  ON perseus.goo (added_on)
  INCLUDE (uid, container_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_added_on_covering IS
'Index on material creation timestamp with covering columns.
Supports time-based queries without table lookups for uid and container_id.
Original: goo.ix_goo_added_on with INCLUDE';

-- Foreign key indexes for goo table
CREATE INDEX idx_goo_container_id 
  ON perseus.goo (container_id)
  TABLESPACE pg_default;

CREATE INDEX idx_goo_recipe_id 
  ON perseus.goo (recipe_id)
  TABLESPACE pg_default;

CREATE INDEX idx_goo_recipe_part_id 
  ON perseus.goo (recipe_part_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_container_id IS
'FK index on container_id - supports JOINs and CASCADE operations.
Critical for container location queries.';

COMMENT ON INDEX perseus.idx_goo_recipe_id IS
'FK index on recipe_id - supports recipe-based material queries.';

COMMENT ON INDEX perseus.idx_goo_recipe_part_id IS
'FK index on recipe_part_id - supports recipe part lineage queries.';

-- ============================================================================
-- Table: material_inventory_threshold
-- ============================================================================

CREATE INDEX idx_material_inventory_threshold_material_type_id 
  ON perseus.material_inventory_threshold (material_type_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_inventory_threshold_material_type_id IS
'Index on material_type_id for threshold queries by material type.
Original: material_inventory_threshold.IX_material_inventory_threshold_material_type_id';

-- ============================================================================
-- Table: material_transition (P0 CRITICAL - Lineage tracking)
-- ============================================================================

CREATE INDEX idx_material_transition_transition_id 
  ON perseus.material_transition (transition_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_transition_transition_id IS
'P0 CRITICAL INDEX: FK index on transition_id for material lineage queries.
Essential for upstream/downstream material tracking.
Original: material_transition.ix_material_transition_transition_id';

-- ============================================================================
-- Table: person
-- ============================================================================

CREATE INDEX idx_person_km_session_id 
  ON perseus.person (km_session_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_person_km_session_id IS
'Index on KM session ID for person session lookups.
Original: person.ix_person_km_session_id';

-- ============================================================================
-- Table: recipe_part
-- ============================================================================

CREATE INDEX idx_recipe_part_unit_id 
  ON perseus.recipe_part (unit_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_unit_id IS
'FK index on unit_id for recipe part unit queries.
Original: recipe_part.ix_recipe_part_unit_id';

-- ============================================================================
-- Table: smurf_goo_type (Analytical method configuration)
-- ============================================================================

CREATE UNIQUE INDEX uq_smurf_goo_type_composite 
  ON perseus.smurf_goo_type (smurf_id, goo_type_id, is_input)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_smurf_goo_type_composite IS
'UNIQUE constraint on smurf_goo_type combination.
Ensures one configuration per smurf/material type/input direction.
Original: smurf_goo_type.uniq_index';

-- ============================================================================
-- Table: transition_material (P0 CRITICAL - Lineage tracking)
-- ============================================================================

CREATE INDEX idx_transition_material_material_id 
  ON perseus.transition_material (material_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_transition_material_material_id IS
'P0 CRITICAL INDEX: FK index on material_id for material lineage queries.
Essential for upstream/downstream material tracking.
Original: transition_material.ix_transition_material_material_id';

-- ============================================================================
-- Table: translated (Materialized view backing table)
-- ============================================================================

CREATE INDEX idx_translated_lineage_composite 
  ON perseus.translated (source_material, destination_material, transition_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_translated_lineage_composite IS
'Composite index on materialized lineage view.
Supports efficient lineage traversal queries.
Note: This may be converted to UNIQUE constraint for materialized view.
Original: translated.ix_materialized';

-- ============================================================================
-- Table: fatsmurf (Analytical sample data)
-- ============================================================================

CREATE INDEX idx_fatsmurf_themis_sample_id 
  ON perseus.fatsmurf (themis_sample_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_themis_sample_id IS
'Index on Themis external system sample ID for integration queries.
Original: fatsmurf.IX_themis_sample_id';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Verify all indexes created
-- SELECT schemaname, tablename, indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'perseus'
--   AND indexname IN (
--     'idx_scraper_active',
--     'idx_container_scope_left_right_depth',
--     'idx_container_type_id_covering',
--     'idx_goo_added_on_covering',
--     'idx_goo_container_id',
--     'idx_goo_recipe_id',
--     'idx_goo_recipe_part_id',
--     'idx_material_inventory_threshold_material_type_id',
--     'idx_material_transition_transition_id',
--     'idx_person_km_session_id',
--     'idx_recipe_part_unit_id',
--     'uq_smurf_goo_type_composite',
--     'idx_transition_material_material_id',
--     'idx_translated_lineage_composite',
--     'idx_fatsmurf_themis_sample_id'
--   )
-- ORDER BY tablename, indexname;

-- Check index sizes
-- SELECT schemaname, tablename, indexname,
--        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'perseus'
-- ORDER BY pg_relation_size(indexrelid) DESC
-- LIMIT 20;

-- ============================================================================
-- END OF 01-missing-sqlserver-indexes.sql
-- ============================================================================
