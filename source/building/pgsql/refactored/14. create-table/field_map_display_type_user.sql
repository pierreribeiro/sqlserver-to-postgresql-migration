-- Table: perseus.field_map_display_type_user
-- Source: SQL Server [dbo].[field_map_display_type_user]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.field_map_display_type_user (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    field_map_display_type_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL
);
