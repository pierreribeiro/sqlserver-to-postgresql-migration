-- ============================================================================
-- File: 29-uq_robot_run_name.sql
-- Table: robot_run
-- Index: uq_robot_run_name
-- Original: robot_run.uniq_run_name
-- ============================================================================
-- Description: Unique constraint on robot run name
-- Columns: name
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Enforce unique run names and support lookups
-- ============================================================================

CREATE UNIQUE INDEX uq_robot_run_name
  ON perseus.robot_run (name)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_robot_run_name IS
'Unique constraint on robot run name.
Ensures each robot run has unique identifier.
Original SQL Server: [uniq_run_name] UNIQUE WITH (FILLFACTOR = 70)
Query pattern: WHERE name = ?';
