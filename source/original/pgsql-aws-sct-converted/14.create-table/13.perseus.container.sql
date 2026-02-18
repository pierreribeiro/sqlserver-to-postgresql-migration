CREATE TABLE perseus_dbo.container(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    container_type_id INTEGER NOT NULL,
    name CITEXT,
    uid CITEXT NOT NULL,
    mass DOUBLE PRECISION,
    left_id INTEGER NOT NULL DEFAULT (1),
    right_id INTEGER NOT NULL DEFAULT (2),
    scope_id CITEXT NOT NULL DEFAULT aws_sqlserver_ext.newid(),
    position_name CITEXT,
    position_x_coordinate CITEXT,
    position_y_coordinate CITEXT,
    depth INTEGER NOT NULL DEFAULT (0),
    created_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp()
)
        WITH (
        OIDS=FALSE
        );

