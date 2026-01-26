-- ============================================================================
-- Object: material_inventory
-- Type: TABLE
-- Priority: P1
-- Description: Material inventory tracking - current locations and quantities
-- ============================================================================

DROP TABLE IF EXISTS perseus.material_inventory CASCADE;

CREATE TABLE perseus.material_inventory (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    material_id INTEGER NOT NULL,
    location_container_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL,
    current_volume_l DOUBLE PRECISION,
    current_mass_kg DOUBLE PRECISION,
    created_by_id INTEGER NOT NULL,
    created_on TIMESTAMP,
    updated_by_id INTEGER,
    updated_on TIMESTAMP,
    allocation_container_id INTEGER,
    recipe_id INTEGER,
    comment TEXT,
    expiration_date DATE,
    CONSTRAINT pk_material_inventory PRIMARY KEY (id)
);

CREATE INDEX idx_material_inventory_material_id ON perseus.material_inventory(material_id);
CREATE INDEX idx_material_inventory_location_container_id ON perseus.material_inventory(location_container_id);
CREATE INDEX idx_material_inventory_is_active ON perseus.material_inventory(is_active);
CREATE INDEX idx_material_inventory_recipe_id ON perseus.material_inventory(recipe_id);

COMMENT ON TABLE perseus.material_inventory IS
'Material inventory tracking - current locations and quantities for materials.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
