-- =============================================================================
-- View: perseus.vw_material_transition_material_up
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_material_transition_material_up-analysis.md
-- Description: Upstream material-to-material link view. Drives from transition_material
--              (all known transition->material destination edges) and LEFT JOINs
--              material_transition to expose the optional upstream source material.
-- Dependencies: perseus.transition_material (base table), perseus.material_transition (base table)
-- Quality Score: 9.4/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Column reference:
--   source_uid:      material_id from material_transition (NULL if no upstream)
--   destination_uid: material_id from transition_material (always populated)
--   transition_uid:  transition_id linking the two materials
--
-- Rows where source_uid IS NULL indicate materials that are the "start"
-- of a lineage chain (no upstream material feeds into their transition).
--
-- Wave:      Wave 0
-- Blocks:    None
-- T-SQL ref: dbo.vw_material_transition_material_up
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_material_transition_material_up (
    source_uid,
    destination_uid,
    transition_uid
) AS
SELECT
    mt.material_id     AS source_uid,
    tm.material_id     AS destination_uid,
    tm.transition_id   AS transition_uid
FROM perseus.transition_material AS tm
LEFT JOIN perseus.material_transition AS mt
    ON tm.transition_id = mt.transition_id;

-- Documentation
COMMENT ON VIEW perseus.vw_material_transition_material_up IS
    'Upstream material link view. Enumerates all transition_material edges with '
    'their optional upstream source material from material_transition. '
    'source_uid is NULL when no material_transition exists for that transition_id '
    '(indicating a lineage chain starting point). '
    'Depends on: transition_material, material_transition (base tables). '
    'T-SQL source: dbo.vw_material_transition_material_up | Migration task T038.';

GRANT SELECT ON perseus.vw_material_transition_material_up TO perseus_app, perseus_readonly;
