-- ============================================================================
-- File: 05-idx_fatsmurf_container_id.sql
-- Table: fatsmurf
-- Index: idx_fatsmurf_container_id
-- Original: fatsmurf.ix_fatsmurf_container_id
-- ============================================================================
-- Description: FK index on container_id
-- Columns: container_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: JOIN optimization with container table
-- ============================================================================

CREATE INDEX idx_fatsmurf_container_id
  ON perseus.fatsmurf (container_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_container_id IS
'FK index on container_id for JOIN optimization with container table.
Supports queries finding experiments by container location.
Original SQL Server: [ix_fatsmurf_container_id] WITH (FILLFACTOR = 90)';
