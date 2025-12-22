CREATE TABLE perseus_dbo.robot_log_transfer(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    source_barcode CITEXT NOT NULL,
    destination_barcode CITEXT NOT NULL,
    transfer_time TIMESTAMP WITHOUT TIME ZONE,
    transfer_volume CITEXT,
    source_position CITEXT,
    destination_position CITEXT,
    material_type_id INTEGER,
    source_material_id INTEGER,
    destination_material_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

