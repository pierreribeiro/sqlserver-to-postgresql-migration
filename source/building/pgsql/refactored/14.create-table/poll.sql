-- Table: perseus.poll
-- Source: SQL Server [dbo].[poll]
-- Columns: 11

CREATE TABLE IF NOT EXISTS perseus.poll (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    smurf_property_id INTEGER NOT NULL,
    fatsmurf_reading_id INTEGER NOT NULL,
    value VARCHAR(2048),
    standard_deviation DOUBLE PRECISION,
    detection INTEGER,
    limit_of_detection DOUBLE PRECISION,
    limit_of_quantification DOUBLE PRECISION,
    lower_calibration_limit DOUBLE PRECISION,
    upper_calibration_limit DOUBLE PRECISION,
    bounds_limit INTEGER
);
