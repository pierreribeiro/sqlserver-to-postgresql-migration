-- Table: perseus.material_inventory_threshold
-- Source: SQL Server [dbo].[material_inventory_threshold]
-- Columns: 12

CREATE TABLE IF NOT EXISTS perseus.material_inventory_threshold (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    material_type_id INTEGER NOT NULL,
    min_item_count INTEGER,
    max_item_count INTEGER,
    min_volume_l DOUBLE PRECISION,
    max_volume_l DOUBLE PRECISION,
    min_mass_kg DOUBLE PRECISION,
    max_mass_kg DOUBLE PRECISION,
    created_by_id INTEGER NOT NULL,
    created_on DATETIME2(7) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by_id INTEGER,
    updated_on DATETIME2(7)
);
