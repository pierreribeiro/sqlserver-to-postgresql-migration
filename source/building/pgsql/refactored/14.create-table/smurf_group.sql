-- Table: perseus.smurf_group
-- Source: SQL Server [dbo].[smurf_group]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.smurf_group (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(150) NOT NULL,
    added_by INTEGER NOT NULL,
    is_public INTEGER NOT NULL DEFAULT 0
);
