CREATE TABLE perseus_dbo.coa_spec(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    coa_id INTEGER NOT NULL,
    property_id INTEGER NOT NULL,
    upper_bound DOUBLE PRECISION,
    lower_bound DOUBLE PRECISION,
    equal_bound CITEXT,
    upper_equal_bound DOUBLE PRECISION,
    lower_equal_bound DOUBLE PRECISION,
    result_precision INTEGER DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

