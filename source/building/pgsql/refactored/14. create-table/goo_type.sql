-- Table: perseus.goo_type
-- Source: SQL Server [dbo].[goo_type]
-- Columns: 12

CREATE TABLE IF NOT EXISTS perseus.goo_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(128) NOT NULL,
    color VARCHAR(50),
    left_id INTEGER NOT NULL,
    right_id INTEGER NOT NULL,
    scope_id VARCHAR(50) NOT NULL,
    disabled INTEGER NOT NULL DEFAULT 0,
    casrn VARCHAR(150),
    iupac VARCHAR(150),
    depth INTEGER NOT NULL DEFAULT 0,
    abbreviation VARCHAR(20),
    density_kg_l DOUBLE PRECISION
);
