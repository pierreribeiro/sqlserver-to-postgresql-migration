-- ============================================================================
-- File: 18-idx_material_transition_transition_id.sql
-- Table: material_transition
-- Index: idx_material_transition_transition_id
-- Original: material_transition.ix_material_transition_transition_id
-- ============================================================================
-- Description: P0 CRITICAL - FK index on transition_id for lineage queries
-- Columns: transition_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Material lineage tracking (upstream/downstream)
-- ============================================================================

CREATE INDEX idx_material_transition_transition_id
  ON perseus.material_transition (transition_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_material_transition_transition_id IS
'P0 CRITICAL INDEX: FK index on transition_id for material lineage queries.
Essential for upstream/downstream material tracking.
Supports: mcgetupstream, mcgetdownstream, translated view.
Original SQL Server: [ix_material_transition_transition_id]
Query pattern: WHERE transition_id = ? (highly frequent in lineage queries)';
