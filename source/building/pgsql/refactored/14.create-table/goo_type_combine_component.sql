-- Table: perseus.goo_type_combine_component
-- Source: SQL Server [dbo].[goo_type_combine_component]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.goo_type_combine_component (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    goo_type_combine_target_id INTEGER NOT NULL,
    goo_type_id INTEGER NOT NULL
);
