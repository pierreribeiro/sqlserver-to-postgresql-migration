-- ============================================================================
-- Object: field_map
-- Type: TABLE
-- Priority: P2
-- Description: Field mapping configuration for display forms
-- ============================================================================

DROP TABLE IF EXISTS perseus.field_map CASCADE;

CREATE TABLE perseus.field_map (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    field_map_block_id INTEGER NOT NULL,
    field_map_type_id INTEGER NOT NULL,
    field_map_set_id INTEGER NOT NULL,
    field_name VARCHAR(100),
    field_label VARCHAR(100),
    field_order INTEGER,
    is_required BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    CONSTRAINT pk_field_map PRIMARY KEY (id)
);

CREATE INDEX idx_field_map_block_id ON perseus.field_map(field_map_block_id);
CREATE INDEX idx_field_map_type_id ON perseus.field_map(field_map_type_id);
CREATE INDEX idx_field_map_set_id ON perseus.field_map(field_map_set_id);

COMMENT ON TABLE perseus.field_map IS
'Field mapping configuration for display forms - defines which fields appear in which forms.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.field_map.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.field_map.field_map_block_id IS 'Foreign key to field_map_block - block grouping';
COMMENT ON COLUMN perseus.field_map.field_map_type_id IS 'Foreign key to field_map_type - field type';
COMMENT ON COLUMN perseus.field_map.field_map_set_id IS 'Foreign key to field_map_set - field set';
COMMENT ON COLUMN perseus.field_map.field_name IS 'Internal field name (database column)';
COMMENT ON COLUMN perseus.field_map.field_label IS 'Display label for field (UI)';
COMMENT ON COLUMN perseus.field_map.field_order IS 'Display order for field';
COMMENT ON COLUMN perseus.field_map.is_required IS 'Whether field is required (default: FALSE)';
COMMENT ON COLUMN perseus.field_map.is_visible IS 'Whether field is visible (default: TRUE)';
