CREATE TABLE perseus_dbo.goo_attachment_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

