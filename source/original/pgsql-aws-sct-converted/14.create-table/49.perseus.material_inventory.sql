CREATE TABLE perseus_dbo.material_inventory(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    material_id INTEGER NOT NULL,
    location_container_id INTEGER NOT NULL,
    is_active NUMERIC(1,0) NOT NULL,
    current_volume_l DOUBLE PRECISION,
    current_mass_kg DOUBLE PRECISION,
    created_by_id INTEGER NOT NULL,
    created_on TIMESTAMP WITHOUT TIME ZONE,
    updated_by_id INTEGER,
    updated_on TIMESTAMP WITHOUT TIME ZONE,
    allocation_container_id INTEGER,
    recipe_id INTEGER,
    comment CITEXT,
    expiration_date DATE
)
        WITH (
        OIDS=FALSE
        );

