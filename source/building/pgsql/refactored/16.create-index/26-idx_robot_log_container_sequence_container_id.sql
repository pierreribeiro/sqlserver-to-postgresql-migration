-- ============================================================================
-- File: 26-idx_robot_log_container_sequence_container_id.sql
-- Table: robot_log_container_sequence
-- Index: idx_robot_log_container_sequence_container_id
-- Original: robot_log_container_sequence.ix_container_id
-- ============================================================================
-- Description: FK index on container_id
-- Columns: container_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Container sequence tracking queries
-- ============================================================================

CREATE INDEX idx_robot_log_container_sequence_container_id
  ON perseus.robot_log_container_sequence (container_id)
  WITH (fillfactor = 100)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_container_sequence_container_id IS
'FK index on container_id for container sequence tracking.
Original SQL Server: [ix_container_id] WITH (FILLFACTOR = 100)
Query pattern: WHERE container_id = ?';
