-- Table: perseus.workflow
-- Source: SQL Server [dbo].[workflow]
-- Columns: 8

CREATE TABLE IF NOT EXISTS perseus.workflow (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(150) NOT NULL,
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL DEFAULT 23,
    disabled INTEGER NOT NULL DEFAULT 0,
    manufacturer_id INTEGER NOT NULL,
    description VARCHAR(1000),
    category VARCHAR(150)
);
