-- ============================================================================
-- Object: display_layout
-- Type: TABLE (Tier 0 Lookup)
-- Priority: P2
-- Description: UI display layout definitions
-- ============================================================================

DROP TABLE IF EXISTS perseus.display_layout CASCADE;

CREATE TABLE perseus.display_layout (
    id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_display_layout PRIMARY KEY (id)
);

CREATE INDEX idx_display_layout_name ON perseus.display_layout(name);

COMMENT ON TABLE perseus.display_layout IS
'UI display layout definitions. Referenced by: field_map_display_type. Updated: 2026-01-26';
