CREATE TABLE perseus_dbo.fatsmurf_comment(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL,
    comment CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

