CREATE TABLE perseus_dbo.robot_log(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER NOT NULL,
    source CITEXT,
    created_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    log_text CITEXT NOT NULL,
    file_name CITEXT,
    robot_log_checksum CITEXT,
    started_on TIMESTAMP WITHOUT TIME ZONE,
    completed_on TIMESTAMP WITHOUT TIME ZONE,
    loaded_on TIMESTAMP WITHOUT TIME ZONE,
    loaded INTEGER NOT NULL DEFAULT (0),
    loadable INTEGER NOT NULL DEFAULT (0),
    robot_run_id INTEGER,
    robot_log_type_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

