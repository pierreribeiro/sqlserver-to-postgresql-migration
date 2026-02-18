-- ============================================================================
-- File: 09-idx_fatsmurf_reading_fatsmurf_id_covering.sql
-- Table: fatsmurf_reading
-- Index: idx_fatsmurf_reading_fatsmurf_id_covering
-- Original: fatsmurf_reading.ix_fsr_for_istd_view
-- ============================================================================
-- Description: Covering index for ISTD view (internal standard view)
-- Columns: fatsmurf_id
-- Include: id
-- Type: NONCLUSTERED with INCLUDE → B-tree with INCLUDE
-- Purpose: Index-only scans for analytical reading queries
-- ============================================================================

CREATE INDEX idx_fatsmurf_reading_fatsmurf_id_covering
  ON perseus.fatsmurf_reading (fatsmurf_id)
  INCLUDE (id)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_reading_fatsmurf_id_covering IS
'Covering index for ISTD (internal standard) view queries.
INCLUDE clause avoids table lookups for id column.
Original SQL Server: [ix_fsr_for_istd_view] INCLUDE ([id]) WITH (FILLFACTOR = 70)
Query pattern: SELECT id FROM fatsmurf_reading WHERE fatsmurf_id = ?';
