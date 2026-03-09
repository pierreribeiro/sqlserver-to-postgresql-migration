-- =============================================================================
-- View: perseus.upstream
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/upstream-analysis.md
-- Description: Recursive CTE view that traverses all upstream material lineage
--              paths. For each destination_material in perseus.translated,
--              walks backward through source_material links to enumerate every
--              (start_point, end_point, path, level) tuple reachable upstream.
-- Dependencies: perseus.translated (materialized view — Wave 0, must be deployed first)
-- Quality Score: 8.6/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- DESIGN NOTES
-- ============
-- 1. Full-graph expansion: This view has no anchor-term filter. It expands
--    the ENTIRE lineage graph for all distinct destination_material values in
--    perseus.translated. Use mcgetupstream(text) for single-node traversal in
--    application code (O(subtree) vs O(N*D) here).
--
-- 2. 'parent' column: The CTE computes 'parent' (pt.destination_material)
--    at each recursive step. It is intentionally omitted from the final
--    projection. Use mcgetupstream() when the 'neighbor' column is required.
--
-- 3. Cycle safety: The WHERE guard in the recursive term eliminates self-loops
--    (a single edge where source == destination) but cannot prevent multi-hop
--    cycles (A→B→A, A→B→C→A). The CYCLE clause (PostgreSQL 14+, ISO SQL
--    standard) is the authoritative guard. It adds is_cycle BOOLEAN and
--    path_array tracking columns to the CTE; the final WHERE NOT is_cycle
--    suppresses cycle rows from output. Cost is zero when no cycles exist.
--
-- 4. Path type TEXT: VARCHAR(255) in the original causes a hard ERROR in
--    PostgreSQL (not silent truncation) when path length exceeds 255 chars.
--    With material_id values up to 50 chars, 6 levels overflows VARCHAR(255).
--    TEXT is unbounded; the m_upstream table's CHECK (length(path) <= 500)
--    is the correct external cap at persistence time.
--
-- 5. Index coverage: The recursive JOIN probes perseus.translated on
--    destination_material (leading column of ix_translated). This is an
--    index seek — no additional index is needed for this access pattern.
--
-- T-SQL source: dbo.upstream
-- Wave:         Wave 1 (after Wave 0: perseus.translated)
-- Migration:    T043 | Branch: us1-critical-views
-- =============================================================================

CREATE OR REPLACE VIEW perseus.upstream AS
WITH RECURSIVE upstream AS (

    -- -------------------------------------------------------------------------
    -- Anchor term
    -- Seed one row per distinct destination_material in translated.
    -- Each destination_material becomes the start_point of an upstream walk.
    -- -------------------------------------------------------------------------
    SELECT
        pt.destination_material          AS start_point,
        pt.destination_material          AS parent,
        pt.source_material               AS child,
        '/'::TEXT                        AS path,
        1                                AS level
    FROM perseus.translated AS pt

    UNION ALL

    -- -------------------------------------------------------------------------
    -- Recursive term
    -- Walk one hop further upstream: join translated where the next edge's
    -- destination_material matches the current frontier child.
    -- The WHERE guard eliminates self-loop edges (source == destination);
    -- multi-hop cycles are handled definitively by the CYCLE clause below.
    -- -------------------------------------------------------------------------
    SELECT
        r.start_point,
        pt.destination_material          AS parent,
        pt.source_material               AS child,
        (r.path || r.child || '/')::TEXT AS path,
        r.level + 1                      AS level
    FROM perseus.translated AS pt
    JOIN upstream AS r
        ON pt.destination_material = r.child
    WHERE pt.destination_material <> pt.source_material

)
-- -----------------------------------------------------------------------------
-- Cycle detection (PostgreSQL 14+, ISO SQL standard).
-- Tracks visited 'child' values per recursive path. Sets is_cycle = TRUE the
-- moment a previously-seen child is encountered. path_array is the internal
-- bookkeeping array used by the engine — not exposed in the final output.
-- Rows where is_cycle = TRUE are suppressed by WHERE NOT is_cycle below.
-- -----------------------------------------------------------------------------
CYCLE child SET is_cycle USING path_array

SELECT
    start_point,
    child   AS end_point,
    path,
    level
FROM upstream
WHERE NOT is_cycle;

-- -----------------------------------------------------------------------------
-- Object documentation (Constitution Article VI — Maintainability)
-- -----------------------------------------------------------------------------
COMMENT ON VIEW perseus.upstream IS
    'Recursive upstream lineage view. For every destination_material in '
    'perseus.translated, enumerates all (start_point, end_point, path, level) '
    'tuples reachable by following source_material links backward. '
    'Covers the full graph — no start-point filter. '
    'Use mcgetupstream(text) for single-node traversal. '
    'Cycle-safe via PostgreSQL 14+ CYCLE clause (CYCLE child SET is_cycle USING path_array). '
    'Path accumulator is TEXT (unbounded); cap enforced by m_upstream CHECK constraint. '
    'Depends on: perseus.translated (materialized view). '
    'Mirror view: perseus.downstream (inverse traversal direction). '
    'T-SQL source: dbo.upstream | Migration task T043.';

-- -----------------------------------------------------------------------------
-- Access grants
-- -----------------------------------------------------------------------------
GRANT SELECT ON perseus.upstream TO perseus_app, perseus_readonly;
