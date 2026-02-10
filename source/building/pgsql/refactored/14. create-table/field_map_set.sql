-- Table: perseus.field_map_set
-- Source: SQL Server [dbo].[field_map_set]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.field_map_set (
    id INTEGER NOT NULL,
    tab_group_id INTEGER,
    display_order INTEGER,
    name VARCHAR(50),
    color VARCHAR(50),
    size INTEGER
);
