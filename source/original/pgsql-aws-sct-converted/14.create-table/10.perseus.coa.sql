CREATE TABLE perseus_dbo.coa(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    goo_type_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

