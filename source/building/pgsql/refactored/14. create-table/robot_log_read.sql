-- Table: perseus.robot_log_read
-- Source: SQL Server [dbo].[robot_log_read]
-- Columns: 7

CREATE TABLE IF NOT EXISTS perseus.robot_log_read (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    source_barcode VARCHAR(25) NOT NULL,
    property_id INTEGER NOT NULL,
    value VARCHAR(25),
    source_position VARCHAR(150),
    source_material_id INTEGER
);
