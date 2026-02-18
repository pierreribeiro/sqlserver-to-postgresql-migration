-- Table: perseus.manufacturer
-- Source: SQL Server [dbo].[manufacturer]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.manufacturer (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(128) NOT NULL,
    location VARCHAR(50),
    goo_prefix VARCHAR(10)
);
