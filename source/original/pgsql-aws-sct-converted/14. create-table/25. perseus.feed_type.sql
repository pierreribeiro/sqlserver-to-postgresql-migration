CREATE TABLE perseus_dbo.feed_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    added_by INTEGER NOT NULL,
    updated_by_id INTEGER,
    name CITEXT,
    description CITEXT,
    correction_method CITEXT NOT NULL DEFAULT 'SIMPLE',
    correction_factor DOUBLE PRECISION NOT NULL DEFAULT (1.0),
    disabled NUMERIC(1,0) NOT NULL DEFAULT (0),
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp()
)
        WITH (
        OIDS=FALSE
        );

