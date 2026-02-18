-- ============================================================================
-- File: 04-idx_fatsmurf_themis_sample_id.sql
-- Table: fatsmurf
-- Index: idx_fatsmurf_themis_sample_id
-- Original: fatsmurf.IX_themis_sample_id
-- ============================================================================
-- Description: Index on Themis external system sample ID
-- Columns: themis_sample_id
-- Type: NONCLUSTERED → B-tree
-- Purpose: External system integration queries
-- ============================================================================

CREATE INDEX idx_fatsmurf_themis_sample_id
  ON perseus.fatsmurf (themis_sample_id)
  WITH (fillfactor = 90)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_fatsmurf_themis_sample_id IS
'Index on Themis external system sample ID for integration queries.
Supports lookups from external Themis LIMS system.
Original SQL Server: [IX_themis_sample_id] WITH (FILLFACTOR = 90)';
