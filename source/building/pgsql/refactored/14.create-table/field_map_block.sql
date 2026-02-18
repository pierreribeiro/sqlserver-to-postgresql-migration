-- Table: perseus.field_map_block
-- Source: SQL Server [dbo].[field_map_block]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.field_map_block (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    filter VARCHAR(150),
    scope VARCHAR(150)
);
