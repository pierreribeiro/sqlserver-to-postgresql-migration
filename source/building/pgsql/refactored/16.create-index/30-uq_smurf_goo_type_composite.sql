-- ============================================================================
-- File: 30-uq_smurf_goo_type_composite.sql
-- Table: smurf_goo_type
-- Index: uq_smurf_goo_type_composite
-- Original: smurf_goo_type.uniq_index
-- ============================================================================
-- Description: Unique constraint on smurf/material type/input direction
-- Columns: smurf_id, goo_type_id, is_input
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Ensure one configuration per smurf/material type/input direction
-- ============================================================================

CREATE UNIQUE INDEX uq_smurf_goo_type_composite
  ON perseus.smurf_goo_type (smurf_id, goo_type_id, is_input)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_smurf_goo_type_composite IS
'UNIQUE constraint on smurf_goo_type combination.
Ensures one configuration per smurf/material type/input direction.
Original SQL Server: [uniq_index] UNIQUE ON (smurf_id, goo_type_id, is_input)
Purpose: Analytical method configuration integrity';
