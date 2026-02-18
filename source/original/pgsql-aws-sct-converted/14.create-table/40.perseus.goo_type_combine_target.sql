CREATE TABLE perseus_dbo.goo_type_combine_target(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_type_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

