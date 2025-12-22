CREATE TABLE perseus_dbo.manufacturer(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    location CITEXT,
    goo_prefix CITEXT
)
        WITH (
        OIDS=FALSE
        );

