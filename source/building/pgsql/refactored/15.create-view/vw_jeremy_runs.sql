-- =============================================================================
-- View: perseus.vw_jeremy_runs
-- Task: T045 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_jeremy_runs-analysis.md
-- Description: Fermentation run report with goo hierarchy traversal. Uses a
--              three-branch recursive CTE ('tree') to traverse goo hierarchies
--              (nested sets + relationship edges) and reports hermes run data
--              with cell harvest and liquid separation process steps.
-- Dependencies: perseus.goo (base table), perseus.goo_relationship (Wave 0 view),
--               perseus.fatsmurf (base table), perseus.goo_type (base table),
--               hermes.run (FDW), hermes.run_condition_value (FDW)
-- Quality Score: 6.7/10 (below STAGING gate — P0 blockers unresolved)
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================

-- ============================================================
-- ⚠️  BLOCKED — Do NOT execute until columns are confirmed
-- Unresolved: column types/names pending #360 resolution
-- See analysis file for blocked column details
-- This file is syntactically valid but deployment is deferred
-- ============================================================

--
-- DEPLOYMENT BLOCKED BY (all three must be resolved before executing):
--
--   Blocker 1 (P0): hermes FDW server not yet configured.
--                   hermes.run and hermes.run_condition_value are FDW tables.
--                   Cannot create this view until the hermes FDW server is live.
--
--   Blocker 2 (P0): goo.tree_scope_key, goo.tree_left_key, goo.tree_right_key
--                   AWS SCT flags these with [9997 - Severity HIGH - Unable to resolve].
--                   These nested-set columns may not exist in the deployed goo table.
--                   Run validation query (1) below before deploying.
--
--   Blocker 3 (P0): fatsmurf.goo_id
--                   AWS SCT flags this with [9997 - Severity HIGH - Unable to resolve].
--                   The fatsmurf.goo_id column may not exist in the deployed table.
--                   Run validation query (2) below before deploying.
--
-- DEPRECATION NOTE: This is a strong deprecation candidate. It is named after
--   an individual analyst ('Jeremy Runs') and contains hardcoded business logic
--   (smurf_id = 23 for cell harvest, smurf_id = 25 for liquid separation,
--   master_condition_id = 65 for vessel size). Confirm active usage with Pierre
--   Ribeiro before investing further refactoring effort.
--
-- PREREQUISITE VALIDATION QUERIES (run on DEV before writing final DDL):
--
--   (1) Verify goo nested-set columns exist:
--       SELECT column_name
--       FROM information_schema.columns
--       WHERE table_schema = 'perseus'
--         AND table_name = 'goo'
--         AND column_name IN ('tree_scope_key', 'tree_left_key', 'tree_right_key');
--       -- Must return 3 rows. If 0 rows, nested-set branch is undeployable as-is.
--
--   (2) Verify fatsmurf.goo_id column exists:
--       SELECT column_name
--       FROM information_schema.columns
--       WHERE table_schema = 'perseus'
--         AND table_name = 'fatsmurf'
--         AND column_name = 'goo_id';
--       -- Must return 1 row. If 0 rows, fatsmurf joins are undeployable as-is.
--
--   (3) Confirm hermes FDW schema name:
--       SELECT nspname FROM pg_namespace WHERE nspname LIKE '%hermes%';
--       -- Confirm this returns 'hermes'; update all hermes.* references below
--       -- if the FDW schema was registered under a different name.
--
-- Wave: Wave 1 (BLOCKED until all three blockers above are resolved)
-- T-SQL source: dbo.vw_jeremy_runs
-- Issues resolved in this DDL (pending blocker resolution):
--   P1-01: Wrong schema perseus_dbo -> perseus; hermes FDW schema assumed 'hermes'
--   P1-02: WITH RECURSIVE added (PostgreSQL requirement)
--   P1-03: CYCLE clause added (PostgreSQL 14+ cycle detection)
--   P2-01: SELECT * in outer query replaced with explicit 10-column projection
--   P2-02: NULL::INTEGER AS parent (explicit cast for UNION type compatibility)
--   P2-04: COMMENT ON VIEW added
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_jeremy_runs (
    experiment,
    run,
    run_label,
    vessel_size,
    feedstock_type,
    strain,
    name,
    description,
    cell_harvest_id,
    liquid_separation_id
) AS
WITH RECURSIVE tree AS (

    -- Anchor: goo materials that have a hermes fermentation run producing them.
    -- r.resultant_material (TEXT) matches g.uid (TEXT).
    SELECT
        g.id                    AS starting_point,
        NULL::INTEGER           AS parent,   -- explicit cast required for UNION ALL type compatibility (P2-02)
        g.id                    AS child
    FROM perseus.goo AS g
    JOIN hermes.run AS r                     -- ⚠️ BLOCKED: hermes FDW schema — confirm name (Blocker 1)
        ON r.resultant_material = g.uid

    UNION ALL

    -- Recursive Branch 2: Nested-set subtree traversal.
    -- For each child goo node, finds all goo records within the same tree scope
    -- whose left/right key range is contained within the parent's range
    -- (classic nested-set descendant predicate).
    SELECT
        r.starting_point,
        g.id                    AS parent,
        c.id                    AS child
    FROM perseus.goo AS g
    JOIN perseus.goo AS c
        ON  c.tree_scope_key = g.tree_scope_key    -- ⚠️ BLOCKED: column existence unconfirmed (Blocker 2)
        AND c.tree_left_key  > g.tree_left_key     -- ⚠️ BLOCKED: column existence unconfirmed (Blocker 2)
        AND c.tree_right_key < g.tree_right_key    -- ⚠️ BLOCKED: column existence unconfirmed (Blocker 2)
    JOIN tree AS r
        ON g.id = r.child

    UNION ALL

    -- Recursive Branch 3: goo_relationship edge traversal.
    -- For each child node, follows goo_relationship edges to find related goo nodes.
    -- Complementary to the nested-set traversal for graph-structured relationships.
    SELECT
        r.starting_point,
        gr.parent,
        gr.child                AS child
    FROM perseus.goo AS g
    JOIN perseus.goo_relationship AS gr
        ON g.id = gr.parent
    JOIN tree AS r
        ON gr.parent = r.child

)
-- Cycle detection: prevents infinite recursion in circular goo hierarchies (PostgreSQL 14+).
-- WHERE NOT t.is_cycle in the outer query filters out any cyclic paths.
CYCLE child SET is_cycle USING path_array

SELECT
    r.experiment_id              AS experiment,
    r.local_id                   AS run,
    r.description                AS run_label,
    rcv.value                    AS vessel_size,
    gt.name                      AS feedstock_type,
    r.strain,
    g.name,
    g.description,
    MIN(cs.id)                   AS cell_harvest_id,
    MIN(ls.id)                   AS liquid_separation_id
FROM hermes.run AS r                             -- ⚠️ BLOCKED: hermes FDW schema — confirm name (Blocker 1)
JOIN perseus.goo AS g
    ON r.resultant_material = g.uid
JOIN tree AS t
    ON g.id = t.starting_point
LEFT JOIN hermes.run_condition_value AS rcv      -- ⚠️ BLOCKED: hermes FDW schema — confirm name (Blocker 1)
    ON rcv.run_id = r.id
   AND rcv.master_condition_id = 65             -- 65 = vessel size condition (hardcoded — verify)
LEFT JOIN perseus.goo AS i
    ON i.uid = r.feedstock_material
LEFT JOIN perseus.goo_type AS gt
    ON gt.id = i.goo_type_id
LEFT JOIN perseus.fatsmurf AS cs
    ON  t.child = cs.goo_id                     -- ⚠️ BLOCKED: fatsmurf.goo_id existence unconfirmed (Blocker 3)
    AND cs.smurf_id = 23                        -- 23 = cell harvest process step (hardcoded — verify)
LEFT JOIN perseus.fatsmurf AS ls
    ON  t.child = ls.goo_id                     -- ⚠️ BLOCKED: fatsmurf.goo_id existence unconfirmed (Blocker 3)
    AND ls.smurf_id = 25                        -- 25 = liquid separation process step (hardcoded — verify)
WHERE NOT t.is_cycle
GROUP BY
    r.experiment_id,
    r.local_id,
    gt.name,
    r.strain,
    g.name,
    g.description,
    r.description,
    rcv.value
HAVING
    -- Filters to runs that have at least one cell harvest or liquid separation step.
    -- HAVING replaces the outer-query WHERE wrapper from the T-SQL original (equivalent).
    MIN(cs.id) IS NOT NULL
    OR MIN(ls.id) IS NOT NULL;

-- Documentation
COMMENT ON VIEW perseus.vw_jeremy_runs IS
    'DEPRECATION CANDIDATE: Person-named view (''Jeremy Runs''). Confirm active usage. '
    'DEPLOYMENT BLOCKED: Requires (1) hermes FDW server configured AND '
    '(2) goo.tree_scope_key/tree_left_key/tree_right_key columns verified on DEV AND '
    '(3) fatsmurf.goo_id column verified on DEV. '
    'Recursive CTE (three branches) traverses goo hierarchy via nested sets and '
    'goo_relationship edges for hermes fermentation runs. Reports cell harvest '
    '(smurf_id=23) and liquid separation (smurf_id=25) process steps per run. '
    'CYCLE clause (PostgreSQL 14+) guards against infinite recursion in circular hierarchies. '
    'HAVING replaces T-SQL outer-subquery WHERE for cell_harvest_id/liquid_separation_id filter. '
    'Depends on: goo, fatsmurf, goo_type (base tables), goo_relationship (Wave 0 view), '
    'hermes.run, hermes.run_condition_value (FDW tables). '
    'T-SQL source: dbo.vw_jeremy_runs | Migration task T045.';

-- GRANT SELECT ON perseus.vw_jeremy_runs TO perseus_app, perseus_readonly;
-- ^ Commented out: do not grant permissions until all P0 blockers are resolved and view is deployed.
