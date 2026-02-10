-- Table: perseus.container
-- Source: SQL Server [dbo].[container]
-- Columns: 13

CREATE TABLE IF NOT EXISTS perseus.container (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    container_type_id INTEGER NOT NULL,
    name VARCHAR(128),
    uid VARCHAR(50) NOT NULL,
    mass DOUBLE PRECISION,
    left_id INTEGER NOT NULL DEFAULT 1,
    right_id INTEGER NOT NULL DEFAULT 2,
    scope_id VARCHAR(50) NOT NULL DEFAULT gen_random_uuid(),
    position_name VARCHAR(50),
    position_x_coordinate VARCHAR(50),
    position_y_coordinate VARCHAR(50),
    depth INTEGER NOT NULL DEFAULT 0,
    created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
