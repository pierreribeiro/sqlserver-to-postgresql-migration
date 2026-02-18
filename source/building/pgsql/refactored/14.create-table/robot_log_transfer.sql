-- Table: perseus.robot_log_transfer
-- Source: SQL Server [dbo].[robot_log_transfer]
-- Columns: 11

CREATE TABLE IF NOT EXISTS perseus.robot_log_transfer (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    source_barcode VARCHAR(25) NOT NULL,
    destination_barcode VARCHAR(25) NOT NULL,
    transfer_time TIMESTAMPTZ,
    transfer_volume VARCHAR(25),
    source_position VARCHAR(150),
    destination_position VARCHAR(150),
    material_type_id INTEGER,
    source_material_id INTEGER,
    destination_material_id INTEGER
);
