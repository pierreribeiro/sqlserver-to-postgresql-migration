-- ============================================================================
-- File: 11-idx_goo_container_id.sql
-- Table: goo
-- Index: idx_goo_container_id
-- Original: goo.ix_goo_container_id
-- ============================================================================
-- Description: FK index on container_id
-- Columns: container_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: JOIN optimization and container location queries
-- ============================================================================

CREATE INDEX idx_goo_container_id
  ON perseus.goo (container_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_goo_container_id IS
'FK index on container_id - supports JOINs and CASCADE operations.
Critical for container location queries.
Original SQL Server: [ix_goo_container_id]
Query pattern: WHERE container_id = ?';
