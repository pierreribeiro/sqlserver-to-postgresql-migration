-- ============================================================================
-- Object: cm_unit
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_unit CASCADE;

CREATE TABLE perseus.cm_unit (
    id INTEGER NOT NULL,
    description VARCHAR(500),
    longname VARCHAR(200),
    dimensions_id INTEGER,
    name VARCHAR(100),
    factor NUMERIC(20,10),
    offset NUMERIC(20,10),

    CONSTRAINT pk_cm_unit PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.cm_unit IS 'CM: Unit of measure definitions. Updated: 2026-01-26';
