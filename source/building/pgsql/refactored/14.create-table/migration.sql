-- Table: perseus.migration
-- Source: SQL Server [dbo].[migration]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.migration (
    id INTEGER NOT NULL,
    description VARCHAR(256) NOT NULL,
    created_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
