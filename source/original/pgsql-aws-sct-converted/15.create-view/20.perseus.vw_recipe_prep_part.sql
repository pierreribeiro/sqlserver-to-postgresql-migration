CREATE OR REPLACE  VIEW perseus_dbo.vw_recipe_prep_part (id, recipe_id, recipe_part_id, prep_id, expected_material_type_id, actual_material_type_id, source_lot_id, volume_l, mass_kg, created_on, created_by_id) AS
SELECT
    split.id AS id, r.id AS recipe_id, rp.id AS recipe_part_id, prep.id AS prep_id, rp.goo_type_id AS expected_material_type_id, split.material_type_id AS actual_material_type_id, src.id AS source_lot_id, split.original_volume AS volume_l, split.original_mass AS mass_kg, split.created_on, split.created_by_id
    FROM perseus_dbo.vw_lot AS split
    JOIN perseus_dbo.vw_lot_edge AS split_to_prep
        ON split_to_prep.src_lot_id = split.id
    JOIN perseus_dbo.vw_lot AS prep
        ON prep.id = split_to_prep.dst_lot_id
    JOIN perseus_dbo.vw_lot_edge AS src_to_split
        ON src_to_split.dst_lot_id = split.id
    JOIN perseus_dbo.vw_lot AS src
        ON src.id = src_to_split.src_lot_id
    JOIN perseus_dbo.recipe AS r
        ON r.id = prep.recipe_id
    JOIN perseus_dbo.recipe_part AS rp
        ON rp.id = split.recipe_part_id AND r.id = rp.recipe_id
    WHERE split.recipe_part_id IS NOT NULL AND prep.recipe_id IS NOT NULL AND split.process_type_id = 110 AND prep.process_type_id = 207;

