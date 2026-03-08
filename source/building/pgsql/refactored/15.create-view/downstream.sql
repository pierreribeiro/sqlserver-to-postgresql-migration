-- =============================================================================
-- View: perseus.downstream
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/downstream-analysis.md
-- Description: Recursive CTE view that traverses the directed material graph
--              forward (source -> destination), returning all downstream
--              descendants of each source material in perseus.translated.
-- Dependencies: perseus.translated (materialized view — Wave 0, must be deployed first)
-- Quality Score: 8.6/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- DESIGN NOTES
-- ============
-- 1. Mirror of perseus.upstream: upstream traverses destination→source;
--    downstream traverses source→destination. For any edge A→B in translated:
--      - upstream  with start_point=B returns A and all ancestors of A.
--      - downstream with start_point=A returns B and all descendants of B.
--
-- 2. Full-graph expansion: No anchor-term filter — the CTE expands the entire
--    graph. For large-graph production queries prefer the cached physical table
--    perseus.m_downstream (populated by usp_updatemdownstream). This view is
--    for freshness when the cache is stale or for DEV/STAGING validation.
--    Callers: mcgetdownstream(), mcgetdownstreambylist().
--
-- 3. Cycle safety: The WHERE guard in the recursive term eliminates self-loops
--    (source == destination on the same edge) but cannot prevent multi-hop
--    cycles (A→B→A, A→B→C→A). The CYCLE clause (PostgreSQL 14+, ISO SQL
--    standard) is the authoritative guard. It tracks (start_point, child) pairs
--    per recursive path and terminates expansion when a pair repeats.
--    is_cycle BOOLEAN and cycle_path ARRAY are added to the CTE internally;
--    WHERE NOT is_cycle in the final SELECT suppresses cycle rows from output.
--    Overhead is negligible when no cycles are present.
--
-- 4. Path width VARCHAR(4000): The original VARCHAR(255) causes a hard ERROR
--    in PostgreSQL (not silent truncation as in SQL Server) when path length
--    exceeds 255 chars. With material_id up to 50 chars, 6 graph levels can
--    overflow. VARCHAR(4000) provides safe headroom beyond the mcgetdownstream
--    function's internal VARCHAR(500) cap, accommodating direct consumers with
--    deeper graph paths.
--
-- 5. Index coverage: The recursive JOIN probes perseus.translated on
--    source_material, which is the leading column of ix_translated
--    (source_material, destination_material, transition_id). This is a
--    leading-column index seek — maximally efficient for this traversal
--    direction. (Contrast with upstream, where destination_material is the
--    leading column and source_material is second.)
--
-- 6. work_mem: For large material graphs, callers should SET work_mem to at
--    least 256MB before querying this view to avoid spilling the recursive
--    working set to disk.
--
-- T-SQL source: dbo.downstream
-- Wave:         Wave 1 (after Wave 0: perseus.translated)
-- Migration:    T043 | Branch: us1-critical-views
-- =============================================================================

CREATE OR REPLACE VIEW perseus.downstream (
    start_point,
    end_point,
    path,
    level
) AS
WITH RECURSIVE downstream AS (

    -- -------------------------------------------------------------------------
    -- Anchor term
    -- Seed one row per edge originating at each source material.
    -- start_point = the root of this forward traversal path.
    -- child       = immediate downstream neighbour (expands in recursive branch).
    -- -------------------------------------------------------------------------
    SELECT
        pt.source_material                                AS start_point,
        pt.source_material                                AS parent,
        pt.destination_material                           AS child,
        CAST('/' AS VARCHAR(4000))                        AS path,
        1                                                 AS level
    FROM perseus.translated AS pt

    UNION ALL

    -- -------------------------------------------------------------------------
    -- Recursive term
    -- Extend each active path by one forward edge.
    -- Join condition: align current frontier (r.child) to the next
    -- source_material in translated.
    -- WHERE guard: skip self-loop edges (source == destination) to prevent
    -- trivial infinite recursion. Multi-hop cycles are handled by CYCLE clause.
    -- -------------------------------------------------------------------------
    SELECT
        r.start_point,
        pt.source_material,
        pt.destination_material,
        CAST(r.path || r.child || '/' AS VARCHAR(4000)),
        r.level + 1
    FROM perseus.translated AS pt
    JOIN downstream          AS r  ON pt.source_material = r.child
    WHERE pt.source_material <> pt.destination_material

)
-- -----------------------------------------------------------------------------
-- Cycle detection (PostgreSQL 14+, ISO SQL standard).
-- Tracks the set of (start_point, child) pairs visited in each recursive path.
-- Sets is_cycle = TRUE when the same pair appears again, terminating that
-- branch. cycle_path is the internal bookkeeping array — not exposed in the
-- final output. WHERE NOT is_cycle strips cycle-sentinel rows, preserving
-- identical result semantics to the original for acyclic graphs while providing
-- safe termination if cycles are present.
-- -----------------------------------------------------------------------------
CYCLE start_point, child SET is_cycle USING cycle_path

SELECT
    start_point,
    child   AS end_point,
    path,
    level
FROM downstream
WHERE NOT is_cycle;

-- -----------------------------------------------------------------------------
-- Object documentation (Constitution Article VI — Maintainability)
-- -----------------------------------------------------------------------------
COMMENT ON VIEW perseus.downstream IS
    'Recursive forward traversal of the material lineage graph. '
    'Returns all downstream descendants for every source material in perseus.translated. '
    'Mirror view of perseus.upstream (which traverses in reverse: destination→source). '
    'Full-graph expansion — no start-point filter. '
    'For large-graph queries prefer the cached perseus.m_downstream table. '
    'Cycle-safe via PostgreSQL 14+ CYCLE clause (CYCLE start_point, child SET is_cycle USING cycle_path). '
    'Path accumulator is VARCHAR(4000); mcgetdownstream() uses VARCHAR(500) internally. '
    'Callers: mcgetdownstream(), mcgetdownstreambylist(). '
    'Depends on: perseus.translated (materialized view). '
    'T-SQL source: dbo.downstream | Migration task T043.';

-- -----------------------------------------------------------------------------
-- Access grants
-- -----------------------------------------------------------------------------
GRANT SELECT ON perseus.downstream TO perseus_app, perseus_readonly;
