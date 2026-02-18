CREATE TABLE perseus_dbo.poll(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    smurf_property_id INTEGER NOT NULL,
    fatsmurf_reading_id INTEGER NOT NULL,
    value CITEXT,
    standard_deviation DOUBLE PRECISION,
    detection INTEGER,
    limit_of_detection DOUBLE PRECISION,
    limit_of_quantification DOUBLE PRECISION,
    lower_calibration_limit DOUBLE PRECISION,
    upper_calibration_limit DOUBLE PRECISION,
    bounds_limit INTEGER
)
        WITH (
        OIDS=FALSE
        );

