-- ============================================================================
-- File: 24-idx_recipe_part_unit_id.sql
-- Table: recipe_part
-- Index: idx_recipe_part_unit_id
-- Original: recipe_part.ix_recipe_part_unit_id
-- ============================================================================
-- Description: FK index on unit_id
-- Columns: unit_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Recipe part unit lookups
-- ============================================================================

CREATE INDEX idx_recipe_part_unit_id
  ON perseus.recipe_part (unit_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_unit_id IS
'FK index on unit_id for recipe part unit lookups.
Original SQL Server: [ix_recipe_part_unit_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE unit_id = ?';
