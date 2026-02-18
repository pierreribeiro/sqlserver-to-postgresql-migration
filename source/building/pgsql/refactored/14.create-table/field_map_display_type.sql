-- Table: perseus.field_map_display_type
-- Source: SQL Server [dbo].[field_map_display_type]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.field_map_display_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    field_map_id INTEGER NOT NULL,
    display_type_id INTEGER NOT NULL,
    display VARCHAR(150) NOT NULL,
    display_layout_id INTEGER NOT NULL DEFAULT 1,
    manditory INTEGER NOT NULL DEFAULT 0
);
