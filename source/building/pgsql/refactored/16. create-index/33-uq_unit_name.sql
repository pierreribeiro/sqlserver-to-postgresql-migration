-- ============================================================================
-- File: 33-uq_unit_name.sql
-- Table: unit
-- Index: uq_unit_name
-- Original: unit.uix_unit_name
-- ============================================================================
-- Description: Unique constraint on unit name
-- Columns: name
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Enforce unique unit names
-- ============================================================================

CREATE UNIQUE INDEX uq_unit_name
  ON perseus.unit (name)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_unit_name IS
'Unique constraint on unit name.
Ensures each measurement unit has unique name.
Original SQL Server: [uix_unit_name] UNIQUE
Query pattern: WHERE name = ?';
