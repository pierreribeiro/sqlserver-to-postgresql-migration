-- ============================================================================
-- File: 01-idx_container_scope_left_right_depth.sql
-- Table: container
-- Index: idx_container_scope_left_right_depth
-- Original: container.ix_container_scope_id_left_id_right_id_depth
-- ============================================================================
-- Description: Composite index for nested set model hierarchy queries
-- Columns: scope_id, left_id, right_id, depth
-- Type: NONCLUSTERED → B-tree
-- Purpose: Efficient ancestor/descendant queries in container hierarchy
-- ============================================================================

CREATE INDEX idx_container_scope_left_right_depth
  ON perseus.container (scope_id, left_id, right_id, depth)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_scope_left_right_depth IS
'Composite index for nested set model hierarchy queries.
Supports efficient ancestor/descendant queries in container hierarchy.
Original SQL Server: [ix_container_scope_id_left_id_right_id_depth]
Query pattern: WHERE scope_id = ? AND left_id BETWEEN ? AND ?';
