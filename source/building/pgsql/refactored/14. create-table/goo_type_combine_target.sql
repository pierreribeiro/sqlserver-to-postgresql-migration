-- Table: perseus.goo_type_combine_target
-- Source: SQL Server [dbo].[goo_type_combine_target]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.goo_type_combine_target (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    goo_type_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL
);
