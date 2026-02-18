CREATE TABLE perseus_dbo.smurf_property(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    property_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT (99),
    smurf_id INTEGER NOT NULL,
    disabled INTEGER NOT NULL DEFAULT (0),
    calculated CITEXT
)
        WITH (
        OIDS=FALSE
        );

