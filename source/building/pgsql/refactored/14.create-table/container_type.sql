-- Table: perseus.container_type
-- Source: SQL Server [dbo].[container_type]
-- Columns: 7

CREATE TABLE IF NOT EXISTS perseus.container_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(128) NOT NULL,
    is_parent INTEGER NOT NULL DEFAULT 1,
    is_equipment INTEGER NOT NULL DEFAULT 0,
    is_single INTEGER NOT NULL DEFAULT 1,
    is_restricted INTEGER NOT NULL DEFAULT 0,
    is_gooable INTEGER NOT NULL DEFAULT 0
);
