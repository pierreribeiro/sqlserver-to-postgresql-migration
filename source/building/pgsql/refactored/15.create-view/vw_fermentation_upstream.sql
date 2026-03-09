-- =============================================================================
-- View: perseus.vw_fermentation_upstream
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_fermentation_upstream-analysis.md
-- Description: Recursive CTE view that traverses upstream process chains,
--              filtering for fermentation process type (smurf_id = 22).
-- Dependencies: perseus.vw_process_upstream (Wave 0 view — must be deployed first)
-- Quality Score: 8.8/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Business logic:
--   Seeds from vw_process_upstream where source_process_type = 22 (fermentation).
--   Traverses upstream through ALL process types but extends path depth and builds
--   the path string only when the destination is also a fermentation-type process.
--   Final result: only rows where process_type = 22 (fermentation nodes only).
--
--   Path format: /<start_process_uid>/<hop1_uid>/<hop2_uid>/...
--
-- T-SQL transformations applied:
--   - schema:    [dbo] / perseus_dbo  -> perseus
--   - concat:    + operator           -> || operator (AWS SCT handled)
--   - path type: VARCHAR(255)         -> TEXT (prevents overflow on deep graphs)
--   - recursion: WITH (implicit)      -> WITH RECURSIVE (explicit — required)
--   - cycle:     no guard             -> CYCLE clause (PostgreSQL 14+)
--   - CTE name:  'upstream'           -> 'fermentation_chain' (avoids shadow of
--                                        perseus.upstream view; cosmetic only)
--   - inequality: !=                  -> <> (ANSI SQL primacy — Article I)
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_fermentation_upstream (
    start_point,
    end_point,
    path,
    level
) AS
WITH RECURSIVE fermentation_chain AS (

    -- -------------------------------------------------------------------------
    -- Anchor: one row per fermentation-typed source process.
    -- Seeds the traversal from every row in vw_process_upstream where the
    -- source process is fermentation type (smurf_id = 22).
    -- destination_process is the start of the traversal chain.
    -- Path initialised as '/<destination_process_uid>'.
    -- -------------------------------------------------------------------------
    SELECT
        pt.destination_process                          AS start_point,
        pt.destination_process                          AS parent,
        pt.destination_process_type                     AS process_type,
        pt.source_process                               AS child,
        ('/' || pt.destination_process)::TEXT           AS path,
        1                                               AS level
    FROM perseus.vw_process_upstream AS pt
    WHERE pt.source_process_type = 22

    UNION ALL

    -- -------------------------------------------------------------------------
    -- Recursive: walk one hop further upstream per iteration.
    -- Joins vw_process_upstream on destination_process = r.child (prior child).
    -- Path and level counters are extended ONLY when the destination process
    -- is also fermentation type (process_type_id = 22). Non-fermentation
    -- processes are traversed but do not contribute to path depth.
    -- Self-loop guard: destination_process <> source_process.
    -- -------------------------------------------------------------------------
    SELECT
        r.start_point,
        pt.destination_process,
        pt.destination_process_type                     AS process_type,
        pt.source_process,
        CASE WHEN pt.destination_process_type = 22
             THEN (r.path || '/' || pt.source_process)::TEXT
             ELSE r.path
        END                                             AS path,
        CASE WHEN pt.destination_process_type = 22
             THEN r.level + 1
             ELSE r.level
        END                                             AS level
    FROM perseus.vw_process_upstream AS pt
    JOIN fermentation_chain AS r
        ON pt.destination_process = r.child
    WHERE pt.destination_process <> pt.source_process

)
-- -----------------------------------------------------------------------------
-- Cycle detection (PostgreSQL 14+).
-- Tracks visited 'child' values per traversal branch using an internal array
-- (path_array). When a previously-visited child is encountered, is_cycle is set
-- to TRUE and recursion terminates for that branch. Rows with is_cycle = TRUE
-- are suppressed by the WHERE clause below.
-- This guards against multi-hop cycles (A->B->A, A->B->C->A) that the simple
-- destination_process <> source_process guard cannot catch.
-- -----------------------------------------------------------------------------
CYCLE child SET is_cycle USING path_array

SELECT
    start_point,
    child       AS end_point,
    path,
    level
FROM fermentation_chain
WHERE process_type = 22
  AND NOT is_cycle;

-- Documentation
COMMENT ON VIEW perseus.vw_fermentation_upstream IS
    'Recursive upstream traversal of fermentation process chains. '
    'Seeds from vw_process_upstream where source_process_type = 22 (fermentation), '
    'walks upstream through all process types, reports only fermentation-type nodes. '
    'Path format: /start_uid/hop1_uid/... — depth and path only extended at fermentation hops. '
    'Cycle-safe via PostgreSQL 14 CYCLE clause (path_array tracks visited child values). '
    'Internal CTE renamed from ''upstream'' to ''fermentation_chain'' to avoid shadowing '
    'the perseus.upstream view — cosmetic change, no behavioral difference. '
    'Depends on: vw_process_upstream (Wave 0 view — must be deployed first). '
    'T-SQL source: dbo.vw_fermentation_upstream | Migration task T043 (analysis T038).';

-- Permissions
GRANT SELECT ON perseus.vw_fermentation_upstream TO perseus_app, perseus_readonly;
