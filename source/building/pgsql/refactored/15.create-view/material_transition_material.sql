-- =============================================================================
-- View: perseus.material_transition_material
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/material_transition_material-analysis.md
-- Description: Thin projection of the translated materialized view with
--              semantic column aliases: source_material → start_point,
--              transition_id unchanged, destination_material → end_point.
-- Dependencies: perseus.translated (materialized view — Wave 0, must be deployed first)
-- Quality Score: 9.5/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- DESIGN NOTES
-- ============
-- 1. This view is a named relational projection of the translated materialized
--    view. It adds no computation — it renames columns to the semantic aliases
--    used by lineage queries: start_point (source), transition_id, end_point
--    (destination).
--
-- 2. Column alias list in the CREATE VIEW header is retained from the AWS SCT
--    output as a deliberate documentation practice (P3-01 from analysis). It
--    makes the view's output schema explicit and independent of the underlying
--    column names in translated.
--
-- 3. No T-SQL-specific constructs exist in the original beyond unqualified
--    table reference and missing schema prefix. The only material change is
--    schema qualification (dbo → perseus) and addition of COMMENT ON VIEW.
--
-- T-SQL source: dbo.material_transition_material
-- Wave:         Wave 1 (after Wave 0: perseus.translated)
-- Migration:    T043 | Branch: us1-critical-views
-- =============================================================================

CREATE OR REPLACE VIEW perseus.material_transition_material (
    start_point,
    transition_id,
    end_point
) AS
SELECT
    source_material      AS start_point,
    transition_id,
    destination_material AS end_point
FROM perseus.translated;

-- -----------------------------------------------------------------------------
-- Object documentation (Constitution Article VI — Maintainability)
-- -----------------------------------------------------------------------------
COMMENT ON VIEW perseus.material_transition_material IS
    'Projection of the translated materialized view with semantic column aliases. '
    'Exposes source_material as start_point, transition_id unchanged, and '
    'destination_material as end_point. Used by lineage queries requiring named '
    'graph edge access. '
    'Depends on: perseus.translated (materialized view). '
    'T-SQL source: dbo.material_transition_material | Migration task T043.';

-- -----------------------------------------------------------------------------
-- Access grants
-- -----------------------------------------------------------------------------
GRANT SELECT ON perseus.material_transition_material TO perseus_app, perseus_readonly;
