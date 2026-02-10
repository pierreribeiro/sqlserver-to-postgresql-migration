-- Table: perseus.external_goo_type
-- Source: SQL Server [dbo].[external_goo_type]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.external_goo_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    goo_type_id INTEGER NOT NULL,
    external_label VARCHAR(250) NOT NULL,
    manufacturer_id INTEGER NOT NULL
);
