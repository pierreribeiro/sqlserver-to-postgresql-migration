-- =============================================================================
-- View: perseus.vw_lot_edge
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_lot_edge-analysis.md
-- Description: Directed edges in the lot lineage graph. Each row is a material
--              transition connecting a source lot to a destination lot.
-- Dependencies: perseus.material_transition (base table),
--               perseus.vw_lot (Wave 0 view — must be deployed first)
-- Quality Score: 9.2/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Business logic:
--   Represents directed edges in the lot lineage graph by joining
--   material_transition to vw_lot twice (self-join pattern):
--
--     sl (source lot):      sl.uid  = mt.material_id
--                           The material that was consumed / started the
--                           transition. sl.id becomes src_lot_id.
--
--     dl (destination lot): dl.process_uid = mt.transition_id
--                           The lot whose producing process step (fatsmurf uid)
--                           matches the transition uid. dl.id becomes dst_lot_id.
--
--   INNER JOIN semantics: only material_transition rows where BOTH the source
--   lot AND the destination lot exist in vw_lot appear. Transitions where the
--   destination lot has not yet been created are excluded — this is intentional.
--
--   created_on is TIMESTAMPTZ from material_transition.added_on (converted
--   during US3 deployment).
--
-- T-SQL transformations applied:
--   - schema:      [dbo] / perseus_dbo -> perseus
--   - quoting:     "vw_lot_edge"       -> vw_lot_edge (no quoting needed)
--   - alias style: 'as' lowercase      -> AS uppercase (constitution style)
--   - added:       COMMENT ON VIEW
--
-- Blocks: perseus.vw_recipe_prep_part (Wave 2 — must deploy this view first)
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_lot_edge (
    src_lot_id,
    dst_lot_id,
    created_on
) AS
SELECT
    sl.id          AS src_lot_id,
    dl.id          AS dst_lot_id,
    mt.added_on    AS created_on
FROM perseus.material_transition AS mt
JOIN perseus.vw_lot AS sl
    ON sl.uid = mt.material_id
JOIN perseus.vw_lot AS dl
    ON dl.process_uid = mt.transition_id;

-- Documentation
COMMENT ON VIEW perseus.vw_lot_edge IS
    'Directed lot lineage graph edges. Each row is a material transition connecting '
    'a source lot (src_lot_id, joined on vw_lot.uid = material_transition.material_id) '
    'to a destination lot (dst_lot_id, joined on vw_lot.process_uid = material_transition.transition_id). '
    'INNER JOIN semantics: only transitions with both a matching source lot AND a matching '
    'destination lot appear. Transitions with no completed destination lot are excluded. '
    'created_on (TIMESTAMPTZ) sourced from material_transition.added_on (US3 conversion). '
    'Foundational for: vw_recipe_prep_part (Wave 2). '
    'Depends on: material_transition (base table), vw_lot (Wave 0 view). '
    'T-SQL source: dbo.vw_lot_edge | Migration task T043 (analysis T038).';

-- Permissions
GRANT SELECT ON perseus.vw_lot_edge TO perseus_app, perseus_readonly;
