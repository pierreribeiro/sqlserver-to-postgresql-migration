-- Table: perseus.fatsmurf_reading
-- Source: SQL Server [dbo].[fatsmurf_reading]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.fatsmurf_reading (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(150) NOT NULL,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL DEFAULT 1
);
