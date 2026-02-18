-- ============================================================================
-- File: 08-idx_fatsmurf_history_fatsmurf_id.sql
-- Table: fatsmurf_history
-- Index: idx_fatsmurf_history_fatsmurf_id
-- Original: fatsmurf_history.ix_fatsmurf_id
-- ============================================================================
-- Description: FK index on fatsmurf_id for history queries
-- Columns: fatsmurf_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Audit trail queries by experiment
-- ============================================================================

CREATE INDEX idx_fatsmurf_history_fatsmurf_id
  ON perseus.fatsmurf_history (fatsmurf_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_history_fatsmurf_id IS
'FK index on fatsmurf_id for audit trail queries.
Supports efficient retrieval of history events for an experiment.
Original SQL Server: [ix_fatsmurf_id] WITH (FILLFACTOR = 70)
Query pattern: WHERE fatsmurf_id = ? ORDER BY history_id DESC';
