CREATE OR REPLACE  VIEW perseus_dbo.vw_lot (id, uid, name, description, material_type_id, process_id, process_uid, process_name, process_description, process_type_id, run_on, duration, container_id, original_volume, original_mass, triton_task_id, recipe_id, recipe_part_id, manufacturer_id, themis_sample_id, catalog_label, created_on, created_by_id) AS
SELECT
    m.id, m.uid, m.name, m.description, m.goo_type_id AS material_type_id, p.id AS process_id, p.uid AS process_uid, p.name AS process_name, p.description AS process_description, p.smurf_id AS process_type_id, p.run_on, p.duration,
    CASE
        WHEN p.container_id IS NOT NULL THEN p.container_id
        ELSE m.container_id
    END AS container_id, m.original_volume, m.original_mass, m.triton_task_id, m.recipe_id, m.recipe_part_id,
    CASE
        WHEN m.manufacturer_id IS NULL THEN p.organization_id
        ELSE m.manufacturer_id
    END AS manufacturer_id, p.themis_sample_id, m.catalog_label, m.added_on AS created_on, m.added_by AS created_by_id
    FROM perseus_dbo.goo AS m
    LEFT OUTER JOIN perseus_dbo.transition_material AS tm
        ON tm.material_id = m.uid
    LEFT OUTER JOIN perseus_dbo.fatsmurf AS p
        ON tm.transition_id = p.uid;

