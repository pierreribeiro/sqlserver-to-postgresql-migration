-- ============================================================================
-- Object: poll
-- Type: TABLE
-- Priority: P3
-- Description: User polling/voting system
-- ============================================================================

DROP TABLE IF EXISTS perseus.poll CASCADE;

CREATE TABLE perseus.poll (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    fatsmurf_reading_id INTEGER NOT NULL,
    smurf_property_id INTEGER NOT NULL,
    poll_value DOUBLE PRECISION,
    poll_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    polled_by INTEGER NOT NULL,
    CONSTRAINT pk_poll PRIMARY KEY (id)
);

CREATE INDEX idx_poll_fatsmurf_reading_id ON perseus.poll(fatsmurf_reading_id);
CREATE INDEX idx_poll_smurf_property_id ON perseus.poll(smurf_property_id);

COMMENT ON TABLE perseus.poll IS
'User polling/voting system - enables user-collected measurements during fermentation.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
