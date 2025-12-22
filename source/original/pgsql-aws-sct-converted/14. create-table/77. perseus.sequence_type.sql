CREATE TABLE perseus_dbo.sequence_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

