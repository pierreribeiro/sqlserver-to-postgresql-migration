-- Table: perseus.property
-- Source: SQL Server [dbo].[property]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.property (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    unit_id INTEGER
);
