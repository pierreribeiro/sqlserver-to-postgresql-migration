-- ============================================================================
-- File: 23-idx_recipe_part_recipe_id.sql
-- Table: recipe_part
-- Index: idx_recipe_part_recipe_id
-- Original: recipe_part.ix_recipe_part_recipe_id
-- ============================================================================
-- Description: FK index on recipe_id
-- Columns: recipe_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Recipe part lookups by parent recipe
-- ============================================================================

CREATE INDEX idx_recipe_part_recipe_id
  ON perseus.recipe_part (recipe_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_part_recipe_id IS
'FK index on recipe_id for recipe part lookups by parent recipe.
Original SQL Server: [ix_recipe_part_recipe_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE recipe_id = ?';
