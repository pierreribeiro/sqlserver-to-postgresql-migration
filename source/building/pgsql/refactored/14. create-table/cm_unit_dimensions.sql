-- ============================================================================
-- Object: cm_unit_dimensions
-- Type: TABLE (Tier 0 - CM)
-- ============================================================================

DROP TABLE IF EXISTS perseus.cm_unit_dimensions CASCADE;

CREATE TABLE perseus.cm_unit_dimensions (
    id INTEGER NOT NULL,
    mass NUMERIC(10,2),
    length NUMERIC(10,2),
    time NUMERIC(10,2),
    electric_current NUMERIC(10,2),
    thermodynamic_temperature NUMERIC(10,2),
    amount_of_substance NUMERIC(10,2),
    luminous_intensity NUMERIC(10,2),
    default_unit_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_cm_unit_dimensions PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.cm_unit_dimensions IS 'CM: SI unit dimension definitions. Updated: 2026-01-26';
