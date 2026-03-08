-- =============================================================================
-- View: perseus.vw_recipe_prep
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_recipe_prep-analysis.md
-- Description: Recipe preparation lots. Filters vw_lot to lots associated with
--              a recipe and produced by a recipe preparation process (type 207).
-- Dependencies: perseus.vw_lot (Wave 0 view — must be deployed first)
-- Quality Score: 9.4/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Business logic:
--   A recipe preparation lot satisfies BOTH conditions:
--     1. recipe_id IS NOT NULL   — lot is associated with a recipe
--     2. process_type_id = 207   — the producing process is fatsmurf smurf_id 207
--                                  (recipe preparation step)
--   Both conditions are independently necessary — a lot can have a recipe_id
--   but a different process type, or process_type_id 207 with no recipe.
--
--   Projects a reduced column set from vw_lot, renaming two physical quantity
--   columns:
--     original_volume -> volume_l   (liters)
--     original_mass   -> mass_kg    (kilograms)
--
-- Column case note:
--   T-SQL original used 'volume_L' (uppercase L). PostgreSQL case-folds unquoted
--   identifiers to lowercase at parse time, so volume_L becomes volume_l.
--   The production DDL uses lowercase volume_l throughout. Application code must
--   reference this column as volume_l (lowercase). Do NOT quote as "volume_L" —
--   that would create a case-sensitive name requiring quoting at every call site.
--
-- Pre-deployment validation:
--   SELECT data_type
--   FROM information_schema.columns
--   WHERE table_schema = 'perseus'
--     AND table_name   = 'fatsmurf'
--     AND column_name  = 'smurf_id';
--   -- Expected: integer (ensures process_type_id = 207 comparison is type-safe)
--
-- T-SQL transformations applied:
--   - schema:     [dbo] / perseus_dbo  -> perseus
--   - quoting:    "vw_recipe_prep"     -> vw_recipe_prep (no quoting needed)
--   - case-fold:  volume_L             -> volume_l (PostgreSQL identifier folding)
--   - added:      COMMENT ON VIEW
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_recipe_prep (
    id,
    name,
    material_type_id,
    container_id,
    recipe_id,
    triton_task_id,
    volume_l,
    mass_kg,
    created_on,
    created_by_id
) AS
SELECT
    prep.id,
    prep.name,
    prep.material_type_id,
    prep.container_id,
    prep.recipe_id,
    prep.triton_task_id,
    prep.original_volume    AS volume_l,
    prep.original_mass      AS mass_kg,
    prep.created_on,
    prep.created_by_id
FROM perseus.vw_lot AS prep
WHERE prep.recipe_id IS NOT NULL
  AND prep.process_type_id = 207;

-- Documentation
COMMENT ON VIEW perseus.vw_recipe_prep IS
    'Recipe preparation lots. Filters vw_lot to lots with recipe_id IS NOT NULL '
    'AND process_type_id = 207 (recipe preparation fatsmurf smurf_id). '
    'Both conditions are independently required. '
    'Projects a reduced column set: volume_l (original_volume in liters), '
    'mass_kg (original_mass in kilograms). '
    'NOTE: column ''volume_l'' uses lowercase ''l'' — PostgreSQL case-folds unquoted '
    'identifiers; T-SQL original declared ''volume_L'' (uppercase L). '
    'Application code must reference this column as ''volume_l'' (lowercase). '
    'Depends on: vw_lot (Wave 0 view — must be deployed first). '
    'T-SQL source: dbo.vw_recipe_prep | Migration task T043 (analysis T038).';

-- Permissions
GRANT SELECT ON perseus.vw_recipe_prep TO perseus_app, perseus_readonly;
