CREATE TABLE perseus_dbo.goo_type_combine_component(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_type_combine_target_id INTEGER NOT NULL,
    goo_type_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

