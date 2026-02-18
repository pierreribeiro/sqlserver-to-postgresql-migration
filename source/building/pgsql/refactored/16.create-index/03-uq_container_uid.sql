-- ============================================================================
-- File: 03-uq_container_uid.sql
-- Table: container
-- Index: uq_container_uid
-- Original: container.uniq_container_uid
-- ============================================================================
-- Description: Unique constraint on container UID
-- Columns: uid
-- Type: UNIQUE NONCLUSTERED → UNIQUE B-tree
-- Purpose: Enforce uniqueness and support lookups by UID
-- ============================================================================

CREATE UNIQUE INDEX uq_container_uid
  ON perseus.container (uid)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.uq_container_uid IS
'Unique constraint on container UID.
Used as FK reference target from multiple tables.
Original SQL Server: [uniq_container_uid] UNIQUE WITH (FILLFACTOR = 90)';
