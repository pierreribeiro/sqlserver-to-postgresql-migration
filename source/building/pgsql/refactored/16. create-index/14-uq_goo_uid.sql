-- ============================================================================
-- File: 14-uq_goo_uid.sql
-- Table: goo
-- Index: uq_goo_uid
-- Original: goo.uniq_goo_uid
-- ============================================================================
-- Description: Unique constraint on goo UID
-- Columns: uid
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Enforce uniqueness and support lookups by UID (P0 CRITICAL)
-- ============================================================================

CREATE UNIQUE INDEX uq_goo_uid
  ON perseus.goo (uid)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_goo_uid IS
'P0 CRITICAL: Unique constraint on goo (material) UID.
Used as FK reference target from transition tables and throughout system.
Original SQL Server: [uniq_goo_uid] UNIQUE WITH (FILLFACTOR = 90)
Query pattern: WHERE uid = ? (highly frequent)';
