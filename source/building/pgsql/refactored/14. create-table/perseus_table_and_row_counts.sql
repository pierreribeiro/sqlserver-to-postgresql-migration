-- ============================================================================
-- Object: perseus_table_and_row_counts
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: Table statistics tracking
-- ============================================================================

DROP TABLE IF EXISTS perseus.perseus_table_and_row_counts CASCADE;

CREATE TABLE perseus.perseus_table_and_row_counts (
    tablename VARCHAR(200),
    rows VARCHAR(50),
    updated_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_perseus_table_row_counts_table ON perseus.perseus_table_and_row_counts(tablename);
CREATE INDEX idx_perseus_table_row_counts_updated ON perseus.perseus_table_and_row_counts(updated_on);

COMMENT ON TABLE perseus.perseus_table_and_row_counts IS
'Table statistics tracking - records row counts per table over time. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.perseus_table_and_row_counts.tablename IS 'Table name';
COMMENT ON COLUMN perseus.perseus_table_and_row_counts.rows IS 'Row count (stored as text)';
COMMENT ON COLUMN perseus.perseus_table_and_row_counts.updated_on IS 'Timestamp when count was recorded';
