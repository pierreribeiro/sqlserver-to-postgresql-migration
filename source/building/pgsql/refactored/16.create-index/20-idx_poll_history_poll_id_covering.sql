-- ============================================================================
-- File: 20-idx_poll_history_poll_id_covering.sql
-- Table: poll_history
-- Index: idx_poll_history_poll_id_covering
-- Original: poll_history.ix_history_id
-- ============================================================================
-- Description: Covering index for poll history queries
-- Columns: poll_id
-- Include: history_id
-- Type: NONCLUSTERED with INCLUDE → B-tree with INCLUDE
-- Purpose: Index-only scans for poll history lookups
-- ============================================================================

CREATE INDEX idx_poll_history_poll_id_covering
  ON perseus.poll_history (poll_id)
  INCLUDE (history_id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_poll_history_poll_id_covering IS
'Covering index for poll history queries with included history_id.
INCLUDE clause avoids table lookups for history_id column.
Original SQL Server: [ix_history_id] ON poll_history(poll_id) INCLUDE(history_id) WITH (FILLFACTOR = 70)
Query pattern: SELECT history_id FROM poll_history WHERE poll_id = ?';
