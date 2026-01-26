-- ============================================================================
-- Object: smurf_property
-- Type: TABLE
-- Priority: P2
-- Description: Properties tracked for smurf (method) executions
-- ============================================================================

DROP TABLE IF EXISTS perseus.smurf_property CASCADE;

CREATE TABLE perseus.smurf_property (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    property_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 99,
    smurf_id INTEGER NOT NULL,
    disabled BOOLEAN NOT NULL DEFAULT FALSE,
    calculated TEXT,
    CONSTRAINT pk_smurf_property PRIMARY KEY (id)
);

CREATE INDEX idx_smurf_property_smurf_id ON perseus.smurf_property(smurf_id);
CREATE INDEX idx_smurf_property_property_id ON perseus.smurf_property(property_id);

COMMENT ON TABLE perseus.smurf_property IS
'Properties tracked for smurf (method) executions - defines which properties are measured/recorded for each method.
Example: smurf_id=10 (PCR) tracks property_id=5 (Tm), property_id=7 (yield).
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.smurf_property.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.smurf_property.property_id IS 'Foreign key to property table - the property to track';
COMMENT ON COLUMN perseus.smurf_property.sort_order IS 'Display order for property (default: 99)';
COMMENT ON COLUMN perseus.smurf_property.smurf_id IS 'Foreign key to smurf table - the method';
COMMENT ON COLUMN perseus.smurf_property.disabled IS 'Whether property tracking is disabled (default: FALSE)';
COMMENT ON COLUMN perseus.smurf_property.calculated IS 'Calculation formula for computed properties (if applicable)';
