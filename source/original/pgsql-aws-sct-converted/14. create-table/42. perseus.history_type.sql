CREATE TABLE perseus_dbo.history_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    format CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

