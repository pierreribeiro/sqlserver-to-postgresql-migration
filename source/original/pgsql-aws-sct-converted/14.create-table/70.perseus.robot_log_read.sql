CREATE TABLE perseus_dbo.robot_log_read(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    source_barcode CITEXT NOT NULL,
    property_id INTEGER NOT NULL,
    value CITEXT,
    source_position CITEXT,
    source_material_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

