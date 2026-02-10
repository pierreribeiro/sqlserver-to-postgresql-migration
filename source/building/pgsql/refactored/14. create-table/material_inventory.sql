-- Table: perseus.material_inventory
-- Source: SQL Server [dbo].[material_inventory]
-- Columns: 14

CREATE TABLE IF NOT EXISTS perseus.material_inventory (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    material_id INTEGER NOT NULL,
    location_container_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL,
    current_volume_l REAL,
    current_mass_kg REAL,
    created_by_id INTEGER NOT NULL,
    created_on TIMESTAMP,
    updated_by_id INTEGER,
    updated_on TIMESTAMP,
    allocation_container_id INTEGER,
    recipe_id INTEGER,
    comment TEXT,
    expiration_date DATE
);
