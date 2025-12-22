CREATE TABLE perseus_dbo.property(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    description CITEXT,
    unit_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

