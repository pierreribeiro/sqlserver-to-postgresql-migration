-- ============================================================================
-- File: 07-uq_fatsmurf_uid.sql
-- Table: fatsmurf
-- Index: uq_fatsmurf_uid
-- Original: fatsmurf.uniq_fs_uid
-- ============================================================================
-- Description: Unique constraint on fatsmurf UID
-- Columns: uid
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Enforce uniqueness and support lookups by UID
-- ============================================================================

CREATE UNIQUE INDEX uq_fatsmurf_uid
  ON perseus.fatsmurf (uid)
  WITH (fillfactor = 70)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_fatsmurf_uid IS
'Unique constraint on fatsmurf (experiment) UID.
Used as FK reference target from transition tables.
Original SQL Server: [uniq_fs_uid] UNIQUE WITH (FILLFACTOR = 70)';
