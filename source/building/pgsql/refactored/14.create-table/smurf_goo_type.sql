-- Table: perseus.smurf_goo_type
-- Source: SQL Server [dbo].[smurf_goo_type]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.smurf_goo_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    smurf_id INTEGER NOT NULL,
    goo_type_id INTEGER,
    is_input INTEGER NOT NULL DEFAULT 0
);
