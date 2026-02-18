-- Table: perseus.perseus_table_and_row_counts
-- Source: SQL Server [dbo].[PerseusTableAndRowCounts]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.perseus_table_and_row_counts (
    table_name VARCHAR(128),
    rows CHAR(11),
    updated_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
