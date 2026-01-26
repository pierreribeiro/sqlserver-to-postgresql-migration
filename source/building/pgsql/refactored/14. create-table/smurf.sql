-- ============================================================================
-- Object: smurf
-- Type: TABLE
-- Priority: P2 (Medium - method definitions)
-- Description: Method/protocol definitions for fermentation experiments
-- ============================================================================

DROP TABLE IF EXISTS perseus.smurf CASCADE;

CREATE TABLE perseus.smurf (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    description VARCHAR(500),
    themis_method_id INTEGER,
    disabled BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_smurf PRIMARY KEY (id)
);

CREATE INDEX idx_smurf_name ON perseus.smurf(name);
CREATE INDEX idx_smurf_class ON perseus.smurf(class_id);
CREATE INDEX idx_smurf_active ON perseus.smurf(disabled) WHERE disabled = FALSE;

COMMENT ON TABLE perseus.smurf IS
'Method/protocol definitions for fermentation experiments.
Referenced by: fatsmurf, smurf_goo_type, smurf_property, workflow_step.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.smurf.id IS 'Primary key';
COMMENT ON COLUMN perseus.smurf.class_id IS 'Method class identifier';
COMMENT ON COLUMN perseus.smurf.name IS 'Method name';
COMMENT ON COLUMN perseus.smurf.description IS 'Method description';
COMMENT ON COLUMN perseus.smurf.themis_method_id IS 'External Themis system method reference';
COMMENT ON COLUMN perseus.smurf.disabled IS 'True if method is disabled (default: FALSE)';
