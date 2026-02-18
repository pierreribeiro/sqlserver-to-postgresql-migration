-- ============================================================================
-- File: 31-idx_submission_added_on.sql
-- Table: submission
-- Index: idx_submission_added_on
-- Original: submission.ix_submission_added_on
-- ============================================================================
-- Description: Time-based index for submission queries
-- Columns: added_on
-- Type: NONCLUSTERED → B-tree
-- Purpose: Time-range submission queries
-- ============================================================================

CREATE INDEX idx_submission_added_on
  ON perseus.submission (added_on)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_submission_added_on IS
'Time-based index for submission queries.
Supports date range and recent submission lookups.
Original SQL Server: [ix_submission_added_on] WITH (FILLFACTOR = 90)
Query pattern: WHERE added_on BETWEEN ? AND ?';
