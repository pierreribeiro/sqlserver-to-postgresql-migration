-- ============================================================================
-- Object: material_inventory_threshold
-- Type: TABLE
-- Priority: P2
-- Description: Reorder thresholds for materials
-- ============================================================================

DROP TABLE IF EXISTS perseus.material_inventory_threshold CASCADE;

CREATE TABLE perseus.material_inventory_threshold (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_type_id INTEGER NOT NULL,
    threshold_volume_l DOUBLE PRECISION,
    threshold_mass_kg DOUBLE PRECISION,
    created_by_id INTEGER NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by_id INTEGER,
    updated_on TIMESTAMP,
    CONSTRAINT pk_material_inventory_threshold PRIMARY KEY (id)
);

CREATE INDEX idx_material_inventory_threshold_goo_type_id ON perseus.material_inventory_threshold(goo_type_id);

COMMENT ON TABLE perseus.material_inventory_threshold IS
'Reorder thresholds for materials - defines when to reorder based on inventory levels.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
