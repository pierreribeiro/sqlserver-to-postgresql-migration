-- ============================================================================
-- File: 16-idx_history_value_history_id.sql
-- Table: history_value
-- Index: idx_history_value_history_id
-- Original: history_value.ix_history_id_value
-- ============================================================================
-- Description: FK index on history_id for key-value lookups
-- Columns: history_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: History attribute queries
-- ============================================================================

CREATE INDEX idx_history_value_history_id
  ON perseus.history_value (history_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_history_value_history_id IS
'FK index on history_id for key-value lookups.
Supports history attribute queries.
Original SQL Server: [ix_history_id_value] WITH (FILLFACTOR = 70)
Query pattern: WHERE history_id = ?';
