-- ============================================================================
-- File: 02-idx_container_type_covering.sql
-- Table: container
-- Index: idx_container_type_covering
-- Original: container.ix_container_type (with INCLUDE)
-- ============================================================================
-- Description: Covering index on container_type_id with included columns
-- Columns: container_type_id
-- Include: id, mass
-- Type: NONCLUSTERED with INCLUDE → B-tree with INCLUDE
-- Purpose: Index-only scans for container type queries
-- ============================================================================

CREATE INDEX idx_container_type_covering
  ON perseus.container (container_type_id)
  INCLUDE (id, mass)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_container_type_covering IS
'Covering index on container_type_id with included columns for index-only scans.
INCLUDE clause avoids table lookups for id and mass columns.
Original SQL Server: [ix_container_type] INCLUDE ([id], [mass]) WITH (FILLFACTOR = 70)
Query pattern: WHERE container_type_id = ?';
