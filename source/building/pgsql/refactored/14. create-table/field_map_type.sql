-- ============================================================================
-- Object: field_map_type
-- Type: TABLE (Tier 0 Lookup)
-- Priority: P2
-- Description: Field mapping type definitions
-- ============================================================================

DROP TABLE IF EXISTS perseus.field_map_type CASCADE;

CREATE TABLE perseus.field_map_type (
    id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_field_map_type PRIMARY KEY (id)
);

CREATE INDEX idx_field_map_type_name ON perseus.field_map_type(name);

COMMENT ON TABLE perseus.field_map_type IS
'Field mapping type definitions. Referenced by: field_map. Updated: 2026-01-26';
