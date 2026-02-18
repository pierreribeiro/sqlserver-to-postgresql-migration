-- ============================================================================
-- File: 13-idx_goo_recipe_part_id.sql
-- Table: goo
-- Index: idx_goo_recipe_part_id
-- Original: goo.ix_goo_recipe_part_id
-- ============================================================================
-- Description: FK index on recipe_part_id
-- Columns: recipe_part_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Recipe part lineage queries
-- ============================================================================

CREATE INDEX idx_goo_recipe_part_id
  ON perseus.goo (recipe_part_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_recipe_part_id IS
'FK index on recipe_part_id - supports recipe part lineage queries.
Original SQL Server: [ix_goo_recipe_part_id]
Query pattern: WHERE recipe_part_id = ?';
