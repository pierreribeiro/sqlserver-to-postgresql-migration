-- ============================================================================
-- File: 25-idx_robot_log_robot_run_id.sql
-- Table: robot_log
-- Index: idx_robot_log_robot_run_id
-- Original: robot_log.ix_robot_log_robot_run_id
-- ============================================================================
-- Description: FK index on robot_run_id
-- Columns: robot_run_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Robot log queries by run
-- ============================================================================

CREATE INDEX idx_robot_log_robot_run_id
  ON perseus.robot_log (robot_run_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_robot_log_robot_run_id IS
'FK index on robot_run_id for robot log queries by run.
Original SQL Server: [ix_robot_log_robot_run_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE robot_run_id = ?';
