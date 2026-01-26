-- ============================================================================
-- Object: cm_unit_compare
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_unit_compare CASCADE;

CREATE TABLE perseus.cm_unit_compare (
    from_unit_id INTEGER NOT NULL,
    to_unit_id INTEGER NOT NULL,

    CONSTRAINT pk_cm_unit_compare PRIMARY KEY (from_unit_id, to_unit_id)
);

COMMENT ON TABLE perseus.cm_unit_compare IS 'CM: Unit comparison mappings. Updated: 2026-01-26';
