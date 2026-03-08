-- =============================================================================
-- View: perseus.goo_relationship
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/goo_relationship-analysis.md
-- Description: Returns parent-child relationships between goo (material) records
--              via merge consolidation and process-ancestry paths.
-- Dependencies: perseus.goo, perseus.fatsmurf
--               hermes.run (FDW — Branch 3 only, excluded in this v1 file)
-- Quality Score: 8.2/10 (v2 full DDL, post-correction)
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- VERSION NOTES
-- -------------
-- This file deploys VERSION 1 (v1): two UNION branches, no FDW dependency.
-- Branch 3 (hermes.run) is excluded and provided as a commented v2 block at the
-- bottom of this file. Replace v1 with v2 once hermes_server FDW is live.
--
-- PRIORITY: P1 (High)
-- WAVE: Wave 0 (local base tables only in this version)
-- BLOCKS: perseus.vw_jeremy_runs (requires v2 with Branch 3 present)
--
-- PREREQUISITE CHECK — run before deploying to confirm column existence:
--   SELECT column_name
--   FROM information_schema.columns
--   WHERE table_schema = 'perseus'
--     AND table_name   = 'goo'
--     AND column_name  IN ('merged_into', 'source_process_id');
--
--   SELECT column_name
--   FROM information_schema.columns
--   WHERE table_schema = 'perseus'
--     AND table_name   = 'fatsmurf'
--     AND column_name  = 'goo_id';
--
-- If any of the three columns are absent, escalate to the DBA team before
-- deploying — the view will fail at CREATE time without them (P1-2 column drift).
-- =============================================================================
-- ============================================================
-- ⚠️  BLOCKED — Do NOT execute until columns are confirmed
-- Columns goo.merged_into, goo.source_process_id, fatsmurf.goo_id
-- are ABSENT from the DEV schema (verified 2026-03-08).
-- Awaiting #360 Topic 1 resolution from SQL Server team.
-- This file is syntactically valid but deployment is deferred.
-- ============================================================

CREATE OR REPLACE VIEW perseus.goo_relationship
    (parent, child)
AS

-- Branch 1: Direct merge relationships.
-- A goo record with merged_into IS NOT NULL has been consolidated into another
-- goo record. The source (id) is the parent; the merge target (merged_into) is
-- the child in the relationship graph.
SELECT
    g.id          AS parent,
    g.merged_into AS child
FROM perseus.goo AS g
WHERE g.merged_into IS NOT NULL

UNION

-- Branch 2: Process-ancestry relationships via fatsmurf.
-- A fatsmurf (fermentation run) links a parent goo (input material) to a child
-- goo (output material) through the source_process_id column on goo.
-- p  = parent goo (produced the fatsmurf run)
-- fs = the fatsmurf run record linking parent to child
-- c  = child goo (created from the fatsmurf run)
SELECT
    p.id AS parent,
    c.id AS child
FROM perseus.goo      AS p
JOIN perseus.fatsmurf AS fs ON fs.goo_id          = p.id
JOIN perseus.goo      AS c  ON c.source_process_id = fs.id;

-- =============================================================================

COMMENT ON VIEW perseus.goo_relationship IS
    'Parent-child relationships between goo (material) records. '
    'VERSION 1 (partial): includes merge relationships (Branch 1) and '
    'process-ancestry via fatsmurf (Branch 2). '
    'Branch 3 (hermes fermentation feedstock/resultant) excluded pending hermes FDW. '
    'Replace with full v2 when hermes_server is configured. '
    'P1 - Wave 0. Blocks: vw_jeremy_runs.';

GRANT SELECT ON perseus.goo_relationship TO perseus_app, perseus_readonly;

-- ============================================================
-- v2 DDL (3-branch version) — PENDING #360 Topic 3 resolution
-- Uncomment when hermes.run column types confirmed (stop_time, run_time)
-- ============================================================

-- -- =============================================================================
-- -- View: perseus.goo_relationship  [VERSION 2 — full, with FDW]
-- -- Source: SQL Server [dbo].[goo_relationship]
-- -- Type: Standard View (3-branch UNION)
-- -- Priority: P1 (High)
-- -- Wave: Wave 0 (depends on local base tables + hermes FDW)
-- -- Depends on: perseus.goo, perseus.fatsmurf, hermes.run (FDW)
-- -- Blocks: perseus.vw_jeremy_runs (P3)
-- -- FDW dependency: hermes.run via hermes_server (postgres_fdw)
-- -- Description: Returns parent-child relationships between goo (material) records.
-- --   Branch 1: Merge relationships (goo records merged into another).
-- --   Branch 2: Process-ancestry relationships via fatsmurf run records.
-- --   Branch 3: Hermes fermentation feedstock-to-resultant material relationships.
-- -- Author: migration US1-critical-views / T037
-- -- Date: 2026-02-19
-- -- =============================================================================
--
-- CREATE OR REPLACE VIEW perseus.goo_relationship
--     (parent, child)
-- AS
-- -- Branch 1: Direct merge relationships.
-- -- A goo record with merged_into IS NOT NULL has been consolidated into another
-- -- goo record. The source (id) is the parent; the merge target (merged_into) is
-- -- the child in the relationship graph.
-- SELECT
--     g.id          AS parent,
--     g.merged_into AS child
-- FROM perseus.goo AS g
-- WHERE g.merged_into IS NOT NULL
--
-- UNION
--
-- -- Branch 2: Process-ancestry relationships via fatsmurf.
-- -- A fatsmurf (fermentation run) links a parent goo (input material) to a child
-- -- goo (output material) through the source_process_id column on goo.
-- SELECT
--     p.id AS parent,
--     c.id AS child
-- FROM perseus.goo      AS p
-- JOIN perseus.fatsmurf AS fs ON fs.goo_id          = p.id
-- JOIN perseus.goo      AS c  ON c.source_process_id = fs.id
--
-- UNION
--
-- -- Branch 3: Hermes fermentation run relationships (FDW).
-- -- A hermes.run record links a feedstock material (input) to a resultant material
-- -- (output) via their UID strings stored in the run table.
-- -- i = goo record for the feedstock (input) material
-- -- o = goo record for the resultant (output) material
-- -- The WHERE clause excludes runs where feedstock and resultant are the same
-- -- (same-material runs have no meaningful parent-child relationship).
-- SELECT
--     i.id AS parent,
--     o.id AS child
-- FROM hermes.run   AS r
-- JOIN perseus.goo  AS i ON i.uid = r.feedstock_material
-- JOIN perseus.goo  AS o ON o.uid = r.resultant_material
-- WHERE COALESCE(r.feedstock_material, '') != COALESCE(r.resultant_material, '');
--
-- COMMENT ON VIEW perseus.goo_relationship IS
--     'Parent-child relationships between goo (material) records. '
--     'Branch 1: merge relationships (merged_into IS NOT NULL). '
--     'Branch 2: process-ancestry via fatsmurf runs (goo.source_process_id). '
--     'Branch 3: hermes fermentation feedstock/resultant pairs (hermes.run FDW). '
--     'UNION deduplicates across all three relationship types. '
--     'P1 - Wave 0. Blocks: vw_jeremy_runs.';
--
-- GRANT SELECT ON perseus.goo_relationship TO perseus_app, perseus_readonly;
