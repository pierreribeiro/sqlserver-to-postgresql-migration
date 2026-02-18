-- ============================================================================
-- File: 32-idx_transition_material_material_id.sql
-- Table: transition_material
-- Index: idx_transition_material_material_id
-- Original: transition_material.ix_transition_material_material_id
-- ============================================================================
-- Description: P0 CRITICAL - FK index on material_id for lineage queries
-- Columns: material_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Material lineage tracking (upstream/downstream)
-- ============================================================================

CREATE INDEX idx_transition_material_material_id
  ON perseus.transition_material (material_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_transition_material_material_id IS
'P0 CRITICAL INDEX: FK index on material_id for material lineage queries.
Essential for upstream/downstream material tracking.
Supports: mcgetupstream, mcgetdownstream, translated view.
Original SQL Server: [ix_transition_material_material_id]
Query pattern: WHERE material_id = ? (highly frequent in lineage queries)';
