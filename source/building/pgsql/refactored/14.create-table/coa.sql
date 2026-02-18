-- Table: perseus.coa
-- Source: SQL Server [dbo].[coa]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.coa (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(150) NOT NULL,
    goo_type_id INTEGER NOT NULL
);
