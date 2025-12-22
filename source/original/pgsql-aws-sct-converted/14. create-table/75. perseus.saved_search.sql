CREATE TABLE perseus_dbo.saved_search(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER,
    name CITEXT NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL,
    is_private INTEGER NOT NULL DEFAULT (1),
    include_downstream INTEGER NOT NULL DEFAULT (0),
    parameter_string CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

