-- Table: perseus.container_type_position
-- Source: SQL Server [dbo].[container_type_position]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.container_type_position (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    parent_container_type_id INTEGER NOT NULL,
    child_container_type_id INTEGER,
    position_name VARCHAR(50),
    position_x_coordinate VARCHAR(50),
    position_y_coordinate VARCHAR(50)
);
