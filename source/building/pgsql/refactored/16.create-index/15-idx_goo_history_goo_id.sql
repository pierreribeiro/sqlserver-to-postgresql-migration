-- ============================================================================
-- File: 15-idx_goo_history_goo_id.sql
-- Table: goo_history
-- Index: idx_goo_history_goo_id
-- Original: goo_history.ix_goo_id
-- ============================================================================
-- Description: FK index on goo_id for history queries
-- Columns: goo_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Audit trail queries by material
-- ============================================================================

CREATE INDEX idx_goo_history_goo_id
  ON perseus.goo_history (goo_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_history_goo_id IS
'FK index on goo_id for audit trail queries.
Supports efficient retrieval of history events for a material.
Original SQL Server: [ix_goo_id] WITH (FILLFACTOR = 70)
Query pattern: WHERE goo_id = ? ORDER BY history_id DESC';
