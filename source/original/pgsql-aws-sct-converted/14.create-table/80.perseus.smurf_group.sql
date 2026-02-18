CREATE TABLE perseus_dbo.smurf_group(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    added_by INTEGER NOT NULL,
    is_public INTEGER NOT NULL DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

