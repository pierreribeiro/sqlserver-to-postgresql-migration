CREATE TABLE perseus_dbo.robot_log_container_sequence(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL,
    sequence_type_id INTEGER NOT NULL,
    processed_on TIMESTAMP WITHOUT TIME ZONE
)
        WITH (
        OIDS=FALSE
        );

