-- =============================================================================
-- View: perseus.vw_recipe_prep_part
-- Task: T046 (US1 Phase 2 — Wave 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_recipe_prep_part-analysis.md
-- Description: Recipe preparation part details — identifies which split lot was
--              used for which recipe part in which recipe preparation.
-- Dependencies: perseus.vw_lot, perseus.vw_lot_edge
-- Quality Score: 8.8/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================

-- =============================================================================
-- View: perseus.vw_recipe_prep_part
-- Description: Recipe preparation part details. Identifies which split lot was
--              used for which recipe part in which recipe preparation.
--
--              Join chain (5 lot/edge instances + 2 base tables):
--              split         — the dispensed/split lot (process_type_id = 110)
--              split_to_prep — edge from split lot to prep lot
--              prep          — the recipe preparation lot (process_type_id = 207)
--              src_to_split  — edge from source lot to split lot
--              src           — the original source material lot
--              recipe r      — the recipe associated with prep.recipe_id
--              recipe_part rp — the part specification matching split.recipe_part_id
--
--              Column semantics:
--              id                        — split lot id (goo.id)
--              recipe_id                 — recipe.id associated with the prep lot
--              recipe_part_id            — recipe_part.id for this split
--              prep_id                   — prep lot id (goo.id)
--              expected_material_type_id — goo_type_id from recipe_part (spec)
--              actual_material_type_id   — goo_type_id from split lot (actual)
--              source_lot_id             — src lot id (original material stock)
--              volume_l                  — split.original_volume (liters)
--              mass_kg                   — split.original_mass (kilograms)
--
--              NOTE: 'volume_l' is lowercase (PostgreSQL case-folds 'volume_L').
--
--              PERFORMANCE: vw_lot evaluated 3x, vw_lot_edge 2x on each query.
--              Run EXPLAIN ANALYZE post-deployment. Consider materializing vw_lot
--              if plan cost is excessive.
--
-- Depends on:  perseus.vw_lot (Wave 0 view)
--              perseus.vw_lot_edge (Wave 1 view — must be deployed before this view)
--              perseus.recipe (base table)
--              perseus.recipe_part (base table)
-- Blocks:      None
-- Wave:        Wave 2 (last wave — requires both Wave 0 and Wave 1)
-- T-SQL ref:   dbo.vw_recipe_prep_part
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_recipe_prep_part (
    id,
    recipe_id,
    recipe_part_id,
    prep_id,
    expected_material_type_id,
    actual_material_type_id,
    source_lot_id,
    volume_l,
    mass_kg,
    created_on,
    created_by_id
) AS
SELECT
    split.id                         AS id,
    r.id                             AS recipe_id,
    rp.id                            AS recipe_part_id,
    prep.id                          AS prep_id,
    rp.goo_type_id                   AS expected_material_type_id,
    split.material_type_id           AS actual_material_type_id,
    src.id                           AS source_lot_id,
    split.original_volume            AS volume_l,
    split.original_mass              AS mass_kg,
    split.created_on,
    split.created_by_id
FROM perseus.vw_lot AS split
JOIN perseus.vw_lot_edge AS split_to_prep
    ON split_to_prep.src_lot_id = split.id
JOIN perseus.vw_lot AS prep
    ON prep.id = split_to_prep.dst_lot_id
JOIN perseus.vw_lot_edge AS src_to_split
    ON src_to_split.dst_lot_id = split.id
JOIN perseus.vw_lot AS src
    ON src.id = src_to_split.src_lot_id
JOIN perseus.recipe AS r
    ON r.id = prep.recipe_id
JOIN perseus.recipe_part AS rp
    ON rp.id = split.recipe_part_id
   AND r.id = rp.recipe_id
WHERE split.recipe_part_id IS NOT NULL
  AND prep.recipe_id IS NOT NULL
  AND split.process_type_id = 110
  AND prep.process_type_id = 207;

-- Documentation
COMMENT ON VIEW perseus.vw_recipe_prep_part IS
    'Recipe preparation part details. Joins split lot -> prep lot -> source lot via '
    'vw_lot_edge, then maps to recipe and recipe_part for expected/actual material type comparison. '
    'Split lot: process_type_id=110 (dispensing). Prep lot: process_type_id=207 (recipe prep). '
    'Column ''volume_l'' lowercase: PostgreSQL case-folds unquoted ''volume_L''. '
    'PERFORMANCE: vw_lot evaluated 3x, vw_lot_edge 2x per query. Run EXPLAIN ANALYZE post-deploy. '
    'Wave 2 (last): requires vw_lot (Wave 0) and vw_lot_edge (Wave 1) to be deployed first. '
    'Depends on: vw_lot, vw_lot_edge (views), recipe, recipe_part (base tables). '
    'T-SQL source: dbo.vw_recipe_prep_part | Migration task T038.';

-- Permissions
GRANT SELECT ON perseus.vw_recipe_prep_part TO perseus_app, perseus_readonly;
