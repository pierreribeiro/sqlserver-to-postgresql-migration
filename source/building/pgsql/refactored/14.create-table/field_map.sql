-- Table: perseus.field_map
-- Source: SQL Server [dbo].[field_map]
-- Columns: 14

CREATE TABLE IF NOT EXISTS perseus.field_map (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    field_map_block_id INTEGER NOT NULL,
    name VARCHAR(50),
    description VARCHAR(250),
    display_order INTEGER,
    setter VARCHAR(150),
    lookup VARCHAR(150),
    lookup_service VARCHAR(250),
    nullable INTEGER,
    field_map_type_id INTEGER NOT NULL,
    database_id VARCHAR(150),
    save_sequence INTEGER NOT NULL,
    onchange VARCHAR(150),
    field_map_set_id INTEGER NOT NULL
);
