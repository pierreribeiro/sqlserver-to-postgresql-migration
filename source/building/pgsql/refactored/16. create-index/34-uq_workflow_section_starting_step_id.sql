-- ============================================================================
-- File: 34-uq_workflow_section_starting_step_id.sql
-- Table: workflow_section
-- Index: uq_workflow_section_starting_step_id
-- Original: workflow_section.uniq_starting_step
-- ============================================================================
-- Description: Unique constraint on starting_step_id
-- Columns: starting_step_id
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Ensure each workflow step is starting step for at most one section
-- ============================================================================

CREATE UNIQUE INDEX uq_workflow_section_starting_step_id
  ON perseus.workflow_section (starting_step_id)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_workflow_section_starting_step_id IS
'Unique constraint on starting_step_id.
Ensures each workflow step is starting step for at most one section.
Original SQL Server: [uniq_starting_step] UNIQUE
Query pattern: WHERE starting_step_id = ?';
