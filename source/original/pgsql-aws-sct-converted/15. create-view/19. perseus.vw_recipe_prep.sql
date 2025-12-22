CREATE OR REPLACE  VIEW perseus_dbo.vw_recipe_prep (id, name, material_type_id, container_id, recipe_id, triton_task_id, volume_l, mass_kg, created_on, created_by_id) AS
SELECT
    prep.id, prep.name, prep.material_type_id, prep.container_id, prep.recipe_id, prep.triton_task_id, prep.original_volume AS volume_l, prep.original_mass AS mass_kg, prep.created_on, prep.created_by_id
    FROM perseus_dbo.vw_lot AS prep
    WHERE prep.recipe_id IS NOT NULL AND prep.process_type_id = 207;

