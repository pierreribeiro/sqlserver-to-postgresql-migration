CREATE TABLE perseus_dbo.material_inventory_threshold(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    material_type_id INTEGER NOT NULL,
    min_item_count INTEGER,
    max_item_count INTEGER,
    min_volume_l DOUBLE PRECISION,
    max_volume_l DOUBLE PRECISION,
    min_mass_kg DOUBLE PRECISION,
    max_mass_kg DOUBLE PRECISION,
    created_by_id INTEGER NOT NULL,
    created_on TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_by_id INTEGER,
    updated_on TIMESTAMP(6) WITHOUT TIME ZONE
)
        WITH (
        OIDS=FALSE
        );

