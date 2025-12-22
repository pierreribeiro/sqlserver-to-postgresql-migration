CREATE TABLE perseus_dbo.unit(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    description CITEXT,
    dimension_id INTEGER,
    factor DOUBLE PRECISION,
    "offset" DOUBLE PRECISION
)
        WITH (
        OIDS=FALSE
        );

