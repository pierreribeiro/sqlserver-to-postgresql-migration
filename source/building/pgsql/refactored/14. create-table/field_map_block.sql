-- ============================================================================
-- Object: field_map_block
-- Type: TABLE (Tier 0)
-- Priority: P2
-- Description: Field mapping block definitions for display configuration
-- ============================================================================

DROP TABLE IF EXISTS perseus.field_map_block CASCADE;

CREATE TABLE perseus.field_map_block (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    filter VARCHAR(200),
    scope VARCHAR(200),

    CONSTRAINT pk_field_map_block PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.field_map_block IS
'Field mapping block definitions for display configuration. Referenced by: field_map. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.field_map_block.filter IS 'Filter expression for field visibility';
COMMENT ON COLUMN perseus.field_map_block.scope IS 'Scope identifier for field mapping';
