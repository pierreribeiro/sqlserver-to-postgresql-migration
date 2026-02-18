-- ============================================================================
-- File: 21-idx_recipe_goo_type_id.sql
-- Table: recipe
-- Index: idx_recipe_goo_type_id
-- Original: recipe.ix_recipe_goo_type_id
-- ============================================================================
-- Description: FK index on goo_type_id
-- Columns: goo_type_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Recipe lookups by material type
-- ============================================================================

CREATE INDEX idx_recipe_goo_type_id
  ON perseus.recipe (goo_type_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_recipe_goo_type_id IS
'FK index on goo_type_id for recipe lookups by material type.
Original SQL Server: [ix_recipe_goo_type_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE goo_type_id = ?';
