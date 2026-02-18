CREATE TABLE perseus_dbo.robot_log_error(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    error_text CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

