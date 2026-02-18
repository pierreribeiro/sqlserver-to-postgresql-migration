CREATE TABLE perseus_dbo.robot_log_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    auto_process INTEGER NOT NULL,
    destination_container_type_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

