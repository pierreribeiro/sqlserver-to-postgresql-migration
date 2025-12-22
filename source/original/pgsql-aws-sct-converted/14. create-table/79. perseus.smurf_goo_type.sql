CREATE TABLE perseus_dbo.smurf_goo_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    smurf_id INTEGER NOT NULL,
    goo_type_id INTEGER,
    is_input INTEGER NOT NULL DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

