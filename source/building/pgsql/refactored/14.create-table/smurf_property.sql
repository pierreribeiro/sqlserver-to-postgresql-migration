-- Table: perseus.smurf_property
-- Source: SQL Server [dbo].[smurf_property]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.smurf_property (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    property_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 99,
    smurf_id INTEGER NOT NULL,
    disabled INTEGER NOT NULL DEFAULT 0,
    calculated VARCHAR(250)
);
