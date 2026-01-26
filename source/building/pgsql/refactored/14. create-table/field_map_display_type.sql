-- ============================================================================
-- Object: field_map_display_type
-- Type: TABLE
-- Priority: P2
-- Description: Maps field mappings to display types and layouts
-- ============================================================================

DROP TABLE IF EXISTS perseus.field_map_display_type CASCADE;

CREATE TABLE perseus.field_map_display_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    field_map_id INTEGER NOT NULL,
    display_type_id INTEGER NOT NULL,
    display_layout_id INTEGER NOT NULL,
    CONSTRAINT pk_field_map_display_type PRIMARY KEY (id)
);

CREATE INDEX idx_field_map_display_type_field_map_id ON perseus.field_map_display_type(field_map_id);
CREATE INDEX idx_field_map_display_type_display_type_id ON perseus.field_map_display_type(display_type_id);
CREATE INDEX idx_field_map_display_type_display_layout_id ON perseus.field_map_display_type(display_layout_id);

COMMENT ON TABLE perseus.field_map_display_type IS
'Maps field mappings to display types and layouts - configures UI rendering.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
