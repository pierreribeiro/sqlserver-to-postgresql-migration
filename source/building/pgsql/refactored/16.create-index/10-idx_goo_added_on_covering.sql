-- ============================================================================
-- File: 10-idx_goo_added_on_covering.sql
-- Table: goo
-- Index: idx_goo_added_on_covering
-- Original: goo.ix_goo_added_on
-- ============================================================================
-- Description: Time-based index with covering columns
-- Columns: added_on
-- Include: uid, container_id
-- Type: NONCLUSTERED with INCLUDE → B-tree with INCLUDE
-- Purpose: Time-based queries without table lookups
-- ============================================================================

CREATE INDEX idx_goo_added_on_covering
  ON perseus.goo (added_on)
  INCLUDE (uid, container_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_added_on_covering IS
'Index on material creation timestamp with covering columns.
Supports time-based queries without table lookups for uid and container_id.
Original SQL Server: [ix_goo_added_on] INCLUDE ([uid], [container_id]) WITH (FILLFACTOR = 90)
Query pattern: WHERE added_on BETWEEN ? AND ?';
