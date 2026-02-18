-- ============================================================================
-- File: 35-idx_translated_composite.sql
-- Table: translated
-- Index: idx_translated_composite
-- Original: translated.ix_materialized (CLUSTERED in SQL Server)
-- ============================================================================
-- Description: Composite index for materialized lineage view
-- Columns: source_material, destination_material, transition_id
-- Type: UNIQUE CLUSTERED → UNIQUE B-tree (PostgreSQL has no clustered indexes)
-- Purpose: Support efficient lineage traversal queries
-- Note: SQL Server had CLUSTERED index - PostgreSQL uses regular B-tree
--       Consider CLUSTER command to physically order table by this index
-- ============================================================================

CREATE UNIQUE INDEX idx_translated_composite
  ON perseus.translated (source_material, destination_material, transition_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_translated_composite IS
'Composite UNIQUE index on materialized lineage view.
Supports efficient lineage traversal queries.
Original SQL Server: [ix_materialized] UNIQUE CLUSTERED WITH (FILLFACTOR = 90)
Note: SQL Server CLUSTERED → PostgreSQL regular B-tree (consider CLUSTER command)
Query pattern: WHERE source_material = ? AND destination_material = ?';
