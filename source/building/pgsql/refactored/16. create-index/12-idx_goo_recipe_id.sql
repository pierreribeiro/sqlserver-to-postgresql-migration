-- ============================================================================
-- File: 12-idx_goo_recipe_id.sql
-- Table: goo
-- Index: idx_goo_recipe_id
-- Original: goo.ix_goo_recipe_id
-- ============================================================================
-- Description: FK index on recipe_id
-- Columns: recipe_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Recipe-based material queries
-- ============================================================================

CREATE INDEX idx_goo_recipe_id
  ON perseus.goo (recipe_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_recipe_id IS
'FK index on recipe_id - supports recipe-based material queries.
Original SQL Server: [ix_goo_recipe_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE recipe_id = ?';
