-- ============================================================================
-- File: 17-idx_material_inventory_threshold_material_type_id.sql
-- Table: material_inventory_threshold
-- Index: idx_material_inventory_threshold_material_type_id
-- Original: material_inventory_threshold.IX_material_inventory_threshold_material_type_id
-- ============================================================================
-- Description: FK index on material_type_id
-- Columns: material_type_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Threshold queries by material type
-- ============================================================================

CREATE INDEX idx_material_inventory_threshold_material_type_id
  ON perseus.material_inventory_threshold (material_type_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_inventory_threshold_material_type_id IS
'FK index on material_type_id for threshold queries by material type.
Original SQL Server: [IX_material_inventory_threshold_material_type_id]
Query pattern: WHERE material_type_id = ?';
