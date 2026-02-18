CREATE TABLE perseus_dbo.smurf(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER NOT NULL,
    name CITEXT NOT NULL,
    description CITEXT,
    themis_method_id INTEGER,
    disabled INTEGER NOT NULL DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

