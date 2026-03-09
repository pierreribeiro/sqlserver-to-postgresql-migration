-- =============================================================================
-- View: perseus.vw_lot
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_lot-analysis.md
-- Description: Foundational lot view. Joins goo (material) to fatsmurf (process)
--              via transition_material to expose lot attributes alongside their
--              producing process attributes. LEFT JOINs ensure materials without
--              an associated process step appear with NULL process columns.
-- Dependencies: perseus.goo (base table), perseus.transition_material (base table),
--               perseus.fatsmurf (base table)
-- Quality Score: 9.1/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Business rules applied:
--   - container_id:    process container preferred over material container
--   - manufacturer_id: material manufacturer preferred over process organization
--
-- Key columns for downstream joins:
--   - uid         (goo.uid, TEXT)       — used by vw_lot_edge ON sl.uid = mt.material_id
--   - process_uid (fatsmurf.uid, TEXT)  — used by vw_lot_edge ON dl.process_uid = mt.transition_id
--
-- Wave:   Wave 0
-- Blocks: perseus.vw_lot_edge, vw_lot_path, vw_recipe_prep (Wave 1)
--         perseus.vw_recipe_prep_part (Wave 2)
-- T-SQL ref: dbo.vw_lot
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_lot (
    id,
    uid,
    name,
    description,
    material_type_id,
    process_id,
    process_uid,
    process_name,
    process_description,
    process_type_id,
    run_on,
    duration,
    container_id,
    original_volume,
    original_mass,
    triton_task_id,
    recipe_id,
    recipe_part_id,
    manufacturer_id,
    themis_sample_id,
    catalog_label,
    created_on,
    created_by_id
) AS
SELECT
    m.id,
    m.uid,
    m.name,
    m.description,
    m.goo_type_id                                                        AS material_type_id,
    p.id                                                                 AS process_id,
    p.uid                                                                AS process_uid,
    p.name                                                               AS process_name,
    p.description                                                        AS process_description,
    p.smurf_id                                                           AS process_type_id,
    p.run_on,
    p.duration,
    CASE WHEN p.container_id IS NOT NULL THEN p.container_id
         ELSE m.container_id
    END                                                                  AS container_id,
    m.original_volume,
    m.original_mass,
    m.triton_task_id,
    m.recipe_id,
    m.recipe_part_id,
    CASE WHEN m.manufacturer_id IS NULL THEN p.organization_id
         ELSE m.manufacturer_id
    END                                                                  AS manufacturer_id,
    p.themis_sample_id,
    m.catalog_label,
    m.added_on                                                           AS created_on,
    m.added_by                                                           AS created_by_id
FROM perseus.goo AS m
LEFT JOIN perseus.transition_material AS tm
    ON tm.material_id = m.uid
LEFT JOIN perseus.fatsmurf AS p
    ON tm.transition_id = p.uid;

-- Documentation
COMMENT ON VIEW perseus.vw_lot IS
    'Foundational lot view. Joins goo (material) to fatsmurf (process) via '
    'transition_material. Materials without an associated process appear with NULL '
    'process columns. Applies two business rules: (1) container_id prefers the '
    'process container over the material container; (2) manufacturer_id prefers '
    'the material manufacturer over the process organization. '
    'Foundational for: vw_lot_edge, vw_lot_path, vw_recipe_prep (Wave 1), '
    'vw_recipe_prep_part (Wave 2). '
    'Depends on: goo, transition_material, fatsmurf (base tables). '
    'T-SQL source: dbo.vw_lot | Migration task T038.';

GRANT SELECT ON perseus.vw_lot TO perseus_app, perseus_readonly;
