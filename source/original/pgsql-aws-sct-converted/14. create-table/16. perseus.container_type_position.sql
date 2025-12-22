CREATE TABLE perseus_dbo.container_type_position(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    parent_container_type_id INTEGER NOT NULL,
    child_container_type_id INTEGER,
    position_name CITEXT,
    position_x_coordinate CITEXT,
    position_y_coordinate CITEXT
)
        WITH (
        OIDS=FALSE
        );

