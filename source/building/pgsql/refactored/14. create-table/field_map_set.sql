-- ============================================================================
-- Object: field_map_set
-- Type: TABLE (Tier 0)
-- Priority: P2
-- Description: Field mapping set definitions
-- ============================================================================

DROP TABLE IF EXISTS perseus.field_map_set CASCADE;

CREATE TABLE perseus.field_map_set (
    id INTEGER NOT NULL,
    tab_group_id INTEGER,
    display_order INTEGER,
    name VARCHAR(100),
    color VARCHAR(50),
    size INTEGER,

    CONSTRAINT pk_field_map_set PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.field_map_set IS
'Field mapping set definitions for grouping related fields. Referenced by: field_map. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.field_map_set.tab_group_id IS 'Tab group identifier';
COMMENT ON COLUMN perseus.field_map_set.display_order IS 'Display order for field sets';
COMMENT ON COLUMN perseus.field_map_set.name IS 'Field set name';
COMMENT ON COLUMN perseus.field_map_set.color IS 'Color code for UI display';
COMMENT ON COLUMN perseus.field_map_set.size IS 'Size parameter for display';
