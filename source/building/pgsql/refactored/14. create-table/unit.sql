-- Table: perseus.unit
-- Source: SQL Server [dbo].[unit]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.unit (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(25) NOT NULL,
    description VARCHAR(150),
    dimension_id INTEGER,
    factor DOUBLE PRECISION,
    offset DOUBLE PRECISION
);
