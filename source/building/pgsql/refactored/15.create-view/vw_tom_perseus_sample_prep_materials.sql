-- =============================================================================
-- View: perseus.vw_tom_perseus_sample_prep_materials
-- Task: T044 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_tom_perseus_sample_prep_materials-analysis.md
-- Description: Aggregates material UIDs for sample preparation inputs (goo types 40
--              and 62) and all downstream lineage derivatives via m_downstream.
-- Dependencies: perseus.goo (base table), perseus.m_downstream (base table)
-- Quality Score: 8.7/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================

-- ============================================================
-- ⚠️  DEPRECATION CANDIDATE — Pending #360 Topic 2 decision
-- This view is deployed but may be removed in a future sprint.
-- Do NOT build new code dependencies on this view.
-- ============================================================

--
-- Business logic:
--   Branch 1: All materials downstream of goo types 40 and 62
--             (via m_downstream.start_point -> goo.uid join)
--   Branch 2: All goo records of type 40 or 62 directly (the goo itself)
--   Combined: Complete set of sample prep input materials and their lineage derivatives.
--
--   goo_type_id 40: [VERIFY — likely a specific feedstock type]
--   goo_type_id 62: [VERIFY — likely a specific sample prep input type]
--
-- Wave: Wave 1 (depends on base tables only; can be deployed in Wave 0)
-- T-SQL source: dbo.vw_tom_perseus_sample_prep_materials
-- Issues resolved:
--   P1-01: Wrong schema perseus_dbo -> perseus (all references)
--   P2-01: Deprecation review flag added (decision pending #360 Topic 2)
--   P2-02: COMMENT ON VIEW added with goo_type_id documentation placeholders
--   P2-03: COMMENT ON VIEW added
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_tom_perseus_sample_prep_materials (
    material_id
) AS

-- Branch 1: Materials downstream of sample prep input types (goo types 40 and 62)
SELECT
    ds.end_point    AS material_id
FROM perseus.goo AS g
JOIN perseus.m_downstream AS ds
    ON ds.start_point = g.uid
WHERE g.goo_type_id IN (40, 62)

UNION

-- Branch 2: Sample prep input materials directly (the goo records themselves)
SELECT
    g.uid           AS material_id
FROM perseus.goo AS g
WHERE g.goo_type_id IN (40, 62);

-- Documentation
COMMENT ON VIEW perseus.vw_tom_perseus_sample_prep_materials IS
    'DEPRECATION CANDIDATE: Person-named view (''Tom Perseus'') with hardcoded type IDs. '
    'Confirm active usage with Pierre Ribeiro before investing further effort. '
    'Sample preparation material aggregation view. Returns the UNION of: '
    '(1) all materials downstream of goo types 40 and 62 via m_downstream, and '
    '(2) all goo records of type 40 or 62 directly. '
    'goo_type_id 40: [verify business meaning — likely a specific feedstock type]. '
    'goo_type_id 62: [verify business meaning — likely a sample prep input type]. '
    'Depends on: goo (base table), m_downstream (base table, populated by reconcile_mupstream). '
    'T-SQL source: dbo.vw_tom_perseus_sample_prep_materials | Migration task T044.';

GRANT SELECT ON perseus.vw_tom_perseus_sample_prep_materials TO perseus_app, perseus_readonly;
