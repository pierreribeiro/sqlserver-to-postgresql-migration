-- ============================================================================
-- Object: smurf_goo_type
-- Type: TABLE
-- Priority: P2
-- Description: Maps smurfs (methods) to valid goo_types (input/output materials)
-- ============================================================================

DROP TABLE IF EXISTS perseus.smurf_goo_type CASCADE;

CREATE TABLE perseus.smurf_goo_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    smurf_id INTEGER NOT NULL,
    goo_type_id INTEGER,
    is_input BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_smurf_goo_type PRIMARY KEY (id)
);

CREATE INDEX idx_smurf_goo_type_smurf_id ON perseus.smurf_goo_type(smurf_id);
CREATE INDEX idx_smurf_goo_type_goo_type_id ON perseus.smurf_goo_type(goo_type_id);

COMMENT ON TABLE perseus.smurf_goo_type IS
'Maps smurfs (methods) to valid goo_types - defines which material types can be inputs/outputs for methods.
Example: smurf_id=10 (PCR) accepts goo_type_id=5 (DNA template) as input, produces goo_type_id=6 (PCR product) as output.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.smurf_goo_type.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.smurf_goo_type.smurf_id IS 'Foreign key to smurf table - the method';
COMMENT ON COLUMN perseus.smurf_goo_type.goo_type_id IS 'Foreign key to goo_type table - the material type';
COMMENT ON COLUMN perseus.smurf_goo_type.is_input IS 'Whether this goo_type is an input (TRUE) or output (FALSE) for the smurf';
