-- Table: perseus.property_option
-- Source: SQL Server [dbo].[property_option]
-- Columns: 5

CREATE TABLE IF NOT EXISTS perseus.property_option (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    property_id INTEGER NOT NULL,
    value INTEGER NOT NULL,
    label VARCHAR(150) NOT NULL,
    disabled INTEGER NOT NULL DEFAULT 0
);
