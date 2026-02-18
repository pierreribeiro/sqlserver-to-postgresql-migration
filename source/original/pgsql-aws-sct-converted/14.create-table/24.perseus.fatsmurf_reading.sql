CREATE TABLE perseus_dbo.fatsmurf_reading(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL DEFAULT (1)
)
        WITH (
        OIDS=FALSE
        );

