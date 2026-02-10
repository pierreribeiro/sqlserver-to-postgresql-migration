-- Table: perseus.sequence_type
-- Source: SQL Server [dbo].[sequence_type]
-- Columns: 2

CREATE TABLE IF NOT EXISTS perseus.sequence_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(25) NOT NULL
);
