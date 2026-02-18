-- ============================================================================
-- File: 06-idx_fatsmurf_smurf_id.sql
-- Table: fatsmurf
-- Index: idx_fatsmurf_smurf_id
-- Original: fatsmurf.ix_fatsmurf_smurf_id (and ix_fatsmurf_recipe_id - duplicate)
-- ============================================================================
-- Description: FK index on smurf_id (analytical method)
-- Columns: smurf_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: JOIN optimization with smurf table
-- Note: SQL Server had TWO indexes with different names but same column (duplicate)
--       - ix_fatsmurf_recipe_id ON fatsmurf(smurf_id)
--       - ix_fatsmurf_smurf_id ON fatsmurf(smurf_id)
--       This single index replaces both.
-- ============================================================================

CREATE INDEX idx_fatsmurf_smurf_id
  ON perseus.fatsmurf (smurf_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_smurf_id IS
'FK index on smurf_id (analytical method) for JOIN optimization.
Supports queries finding experiments by analytical method.
Original SQL Server: [ix_fatsmurf_smurf_id] and [ix_fatsmurf_recipe_id] (duplicate removed)
Note: SQL Server had duplicate indexes on same column with different names';
