-- ============================================================================
-- Object: fatsmurf_reading
-- Type: TABLE
-- Priority: P2
-- Description: Sensor readings during fermentation experiments
-- ============================================================================

DROP TABLE IF EXISTS perseus.fatsmurf_reading CASCADE;

CREATE TABLE perseus.fatsmurf_reading (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    reading_timestamp TIMESTAMP NOT NULL,
    reading_type VARCHAR(100) NOT NULL,
    reading_value DOUBLE PRECISION,
    reading_unit VARCHAR(50),
    added_by INTEGER NOT NULL,
    CONSTRAINT pk_fatsmurf_reading PRIMARY KEY (id)
);

CREATE INDEX idx_fatsmurf_reading_fatsmurf_id ON perseus.fatsmurf_reading(fatsmurf_id);
CREATE INDEX idx_fatsmurf_reading_timestamp ON perseus.fatsmurf_reading(reading_timestamp);
CREATE INDEX idx_fatsmurf_reading_type ON perseus.fatsmurf_reading(reading_type);

COMMENT ON TABLE perseus.fatsmurf_reading IS
'Sensor readings during fermentation experiments - stores time-series fermentation data (pH, temperature, OD, etc.).
Updated: 2026-01-26 | Owner: Perseus DBA Team';
