CREATE TABLE perseus_dbo.external_goo_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_type_id INTEGER NOT NULL,
    external_label CITEXT NOT NULL,
    manufacturer_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

