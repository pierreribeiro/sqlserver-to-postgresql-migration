-- ============================================================================
-- File: 28-idx_robot_log_transfer_robot_log_id.sql
-- Table: robot_log_transfer
-- Index: idx_robot_log_transfer_robot_log_id
-- Original: robot_log_transfer.ix_robot_log_transfer_robot_log_id
-- ============================================================================
-- Description: FK index on robot_log_id
-- Columns: robot_log_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Robot transfer tracking by log entry
-- ============================================================================

CREATE INDEX idx_robot_log_transfer_robot_log_id
  ON perseus.robot_log_transfer (robot_log_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_transfer_robot_log_id IS
'FK index on robot_log_id for robot transfer tracking.
Original SQL Server: [ix_robot_log_transfer_robot_log_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE robot_log_id = ?';
