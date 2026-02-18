-- ============================================================================
-- File: 19-idx_person_km_session_id.sql
-- Table: person
-- Index: idx_person_km_session_id
-- Original: person.ix_person_km_session_id
-- ============================================================================
-- Description: FK index on km_session_id
-- Columns: km_session_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: Person session lookups
-- ============================================================================

CREATE INDEX idx_person_km_session_id
  ON perseus.person (km_session_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_person_km_session_id IS
'FK index on KM session ID for person session lookups.
Original SQL Server: [ix_person_km_session_id] WITH (FILLFACTOR = 90)
Query pattern: WHERE km_session_id = ?';
