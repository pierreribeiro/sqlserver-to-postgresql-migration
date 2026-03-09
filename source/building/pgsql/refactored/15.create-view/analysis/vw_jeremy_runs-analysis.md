# Analysis: vw_jeremy_runs (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_jeremy_runs` |
| PostgreSQL name | `perseus.vw_jeremy_runs` |
| Type | Recursive CTE View |
| Priority | P3 |
| Complexity | 6/10 |
| Wave | Wave 1 (depends on `goo_relationship`, requires hermes FDW) |
| Depends on | `perseus.goo` (base table ✅), `perseus.goo_relationship` (P1 Wave 0 view — ⚠️ FDW blocked), `perseus.fatsmurf` (base table ✅), `perseus.goo_type` (base table ✅), `hermes.run` (FDW ⚠️), `hermes.run_condition_value` (FDW ⚠️) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | hermes (CRITICAL BLOCKER — cannot deploy until hermes FDW server is live) |
| Deprecation Status | DEPRECATION CANDIDATE — see analysis below |
| SQL Server file | `source/original/sqlserver/10.create-view/12.perseus.dbo.vw_jeremy_runs.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/12.perseus.vw_jeremy_runs.sql` |

---

## Deprecation Flag (Priority Decision)

**STRONG DEPRECATION CANDIDATE — ASSESS BEFORE INVESTING REFACTORING TIME.**

Indicators:
1. **Named after a person** — "Jeremy Runs" naming convention indicates a person-specific report view.
2. **Most complex P3 view** — Three-branch recursive CTE with FDW dependency. High refactoring investment.
3. **FDW dependency** — Cannot be deployed until the hermes FDW server connection is established (a separate infrastructure task).
4. **goo nested sets** — References `goo.tree_scope_key`, `goo.tree_left_key`, `goo.tree_right_key` — columns that AWS SCT flags as `[9997 - Severity HIGH - Unable to resolve]`. These columns may not exist in the deployed `goo` table (they are nested-set tree traversal columns that may have been removed during the US3 migration).
5. **`fatsmurf.goo_id` column** — AWS SCT also flags `goo_id` as `[9997 - Severity HIGH - Unable to resolve]` in the `fatsmurf` table. If `fatsmurf.goo_id` does not exist, this view cannot be refactored as-is.

**Recommendation to Pierre Ribeiro:**
1. Confirm whether this view is actively used by any application or report.
2. Confirm whether `goo.tree_scope_key`, `goo.tree_left_key`, `goo.tree_right_key` exist in the deployed `goo` table.
3. Confirm whether `fatsmurf.goo_id` exists in the deployed `fatsmurf` table.
4. If any of these columns are missing, this view is **undeployable as-is** regardless of hermes FDW status.

**If confirmed deprecated:** Do not deploy. Document.
**If still in use AND columns exist AND hermes FDW is ready:** Use the proposed minimal DDL below as a starting point, but expect significant additional validation effort.

**Effort classification change: If NOT deprecated, this view is P1 effort in a P3 priority envelope.**

---

## Source Query Analysis

The view uses a three-branch recursive CTE (`Tree`) to traverse goo hierarchies and then aggregates hermes run data:

**Anchor — hermes runs → goo materials:**
```sql
SELECT g.id AS starting_point, NULL AS parent, g.id AS child
FROM dbo.goo g
JOIN hermes.run r ON r.resultant_material = g.uid
```
Seeds one row per goo record that has a hermes run producing it. `r.resultant_material` is a TEXT material UID matching `g.uid`.

**Recursive Branch 2 — Nested set tree traversal:**
```sql
SELECT r.starting_point, g.id, c.id AS child
FROM dbo.goo g
JOIN dbo.goo c ON c.tree_scope_key = g.tree_scope_key
                AND c.tree_left_key > g.tree_left_key
                AND c.tree_right_key < g.tree_right_key
JOIN Tree r ON g.id = r.child
```
Traverses the nested-set tree structure encoded in `goo` — for each `child` goo node, finds all `goo c` rows that are within the same tree scope and within the left/right key range (nested set subtree containment predicate). This is the classic nested-set tree descendant traversal pattern.

**Recursive Branch 3 — goo_relationship traversal:**
```sql
SELECT r.starting_point, gr.parent, gr.child AS child
FROM dbo.goo g
JOIN dbo.goo_relationship gr ON g.id = gr.parent
JOIN Tree r ON gr.parent = r.child
```
For each `child` node, follows `goo_relationship` edges to find related goo nodes. This is a graph edge traversal complementary to the nested-set traversal.

**Final aggregation:**
```sql
SELECT r.experiment_id AS experiment, r.local_id AS run,
       r.description AS run_label, rcv.value AS vessel_size,
       gt.name AS feedstock_type, r.strain, g.name, g.description,
       MIN(cs.id) AS cell_harvest_id, MIN(ls.id) AS liquid_separation_id
FROM hermes.run r
JOIN dbo.goo g ON r.resultant_material = g.uid
JOIN Tree t ON g.id = t.starting_point
LEFT JOIN hermes.run_condition_value rcv ON rcv.run_id = r.id AND rcv.master_condition_id = 65
LEFT JOIN dbo.goo i ON i.uid = r.feedstock_material
LEFT JOIN dbo.goo_type gt ON gt.id = i.goo_type_id
LEFT JOIN dbo.fatsmurf cs ON t.child = cs.goo_id AND cs.smurf_id = 23
LEFT JOIN dbo.fatsmurf ls ON t.child = ls.goo_id AND ls.smurf_id = 25
GROUP BY r.experiment_id, r.local_id, gt.name, r.strain, g.name, g.description, r.description, rcv.value
```
Joins the tree result to hermes runs, hermes run condition values, feedstock goo type, and fatsmurf process records to identify cell harvest (smurf_id=23) and liquid separation (smurf_id=25) process steps for each run.

**Business interpretation:** This view finds all fermentation runs from hermes, traces the goo hierarchy for each run's output material (both via nested sets and via goo_relationship edges), and identifies whether a cell harvest (CS) and liquid separation (LS) process step occurred anywhere in the material tree.

---

## Critical Blockers

### Blocker 1 — hermes FDW Not Available

**Severity:** P0 (deployment blocker)
**Description:** `hermes.run` and `hermes.run_condition_value` are FDW tables. The hermes FDW server connection is documented as pending in `MIGRATION-SEQUENCE.md`. This view CANNOT be deployed until the hermes FDW server is live.
**Fix:** Deploy only after hermes FDW is configured. Track in infrastructure task backlog.

### Blocker 2 — `goo.tree_scope_key`, `goo.tree_left_key`, `goo.tree_right_key` — columns may not exist

**Severity:** P0 (if columns absent, deployment fails)
**Description:** AWS SCT flags all three nested-set columns with `[9997 - Severity HIGH - Unable to resolve the object]`. These columns either:
(a) Do not exist in the PostgreSQL `goo` table (they may have been intentionally excluded during US3 table migration as a deprecated nested-set implementation), or
(b) Exist under different names.
**Fix:** Run `\d perseus.goo` on DEV to check for these columns. If absent, the nested-set branch of the CTE cannot be written without knowing the alternative column names or tree traversal strategy.

### Blocker 3 — `fatsmurf.goo_id` — column may not exist

**Severity:** P0 (if column absent, deployment fails)
**Description:** AWS SCT flags `goo_id` in `fatsmurf` with the same `[9997 - Severity HIGH]` error. The `fatsmurf` table joins are:
- `LEFT JOIN dbo.fatsmurf cs ON t.child = cs.goo_id AND cs.smurf_id = 23`
- `LEFT JOIN dbo.fatsmurf ls ON t.child = ls.goo_id AND ls.smurf_id = 25`
If `fatsmurf.goo_id` does not exist (or has a different name), these joins cannot be written as-is.
**Fix:** Run `\d perseus.fatsmurf` on DEV to confirm whether `goo_id` exists.

---

## Issue Register

### P0 Issues

#### P0-01 — hermes FDW not available (deployment blocker)
See Blocker 1 above.

#### P0-02 — `goo.tree_scope_key/tree_left_key/tree_right_key` may not exist
See Blocker 2 above.

#### P0-03 — `fatsmurf.goo_id` may not exist
See Blocker 3 above.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`; `hermes.*` → FDW schema

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT correctly converts `dbo.*` to `perseus_dbo.*` (wrong schema) and `hermes.*` to `perseus_hermes.*`. In production:
- `dbo.*` → `perseus.*`
- `hermes.*` → the FDW schema configured for hermes (likely `hermes` or `hermes_fdw` — verify with DBA at hermes FDW setup time)

**Fix:** After schema correction, confirm the FDW schema name matches the hermes FDW server configuration.

---

#### P1-02 — `WITH RECURSIVE` required in PostgreSQL

**Severity:** P1
**Location:** CTE declaration
**Description:** T-SQL infers recursive status; PostgreSQL requires explicit `WITH RECURSIVE`. AWS SCT correctly adds this.
**Fix:** AWS SCT handles this. Verify production DDL retains `WITH RECURSIVE`.

---

#### P1-03 — Three-branch UNION ALL in recursive CTE — cycle risk

**Severity:** P1
**Location:** Recursive CTE — two recursive branches
**Description:** Both recursive branches (nested set and goo_relationship) can potentially revisit the same `child` node, particularly in complex goo hierarchies. The single `child` column is the recursion key. A `CYCLE child SET is_cycle USING path_array` clause is recommended for both protective and diagnostic purposes.
**Fix:** Add CYCLE clause. Filter `WHERE NOT is_cycle` in final SELECT.

---

### P2 Issues

#### P2-01 — `SELECT *` in outer query

**Severity:** P2 (maintainability)
**Location:** Outer `SELECT * FROM (...) d`
**Description:** The final SELECT uses `SELECT * FROM (SELECT ...) d` which returns all columns from the aggregation subquery. The 10 output columns should be enumerated explicitly in the CREATE VIEW header and in the outer SELECT for maintainability.
**Fix:** Add explicit column list to CREATE VIEW header and replace `SELECT *` with explicit column projection.

---

#### P2-02 — `NULL AS parent` in anchor term — CAST required for type inference

**Severity:** P2
**Location:** Anchor — `NULL AS parent`
**Description:** PostgreSQL requires that UNION arms have compatible types. `NULL` without a CAST has type `unknown`. The recursive branches produce `g.id` (INTEGER) as `parent`. PostgreSQL may infer this correctly but explicit typing is safer.
**Fix:** Use `NULL::INTEGER AS parent` in the anchor term.

---

#### P2-03 — Deprecation review required before deployment

**Severity:** P2 (process)
**Location:** Deployment decision
**Description:** See Deprecation Flag above.

---

#### P2-04 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_jeremy_runs IS '...'`.

---

### P3 Issues

#### P3-01 — `!=` → `<>` (ANSI preference)

**Severity:** P3
**Location:** Not present explicitly in the recursive WHERE — the WHERE guards in the three-branch CTE don't use `!=`. Noted for completeness.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW vw_jeremy_runs AS WITH Tree AS (...)` | `CREATE OR REPLACE VIEW perseus.vw_jeremy_runs AS WITH RECURSIVE tree AS (...)` | DDL header + CTE | `WITH RECURSIVE` required; lowercase `tree` (snake_case) |
| `dbo.goo` (×6 occurrences) | `perseus.goo` | All branches | Schema correction |
| `hermes.run` | FDW schema + `.run` | Anchor + final join | Confirm FDW schema at hermes setup time |
| `hermes.run_condition_value` | FDW schema + `.run_condition_value` | Final join | Confirm FDW schema |
| `dbo.goo_relationship` | `perseus.goo_relationship` | Recursive branch 3 | Schema correction |
| `dbo.goo_type` | `perseus.goo_type` | Final join | Schema correction |
| `dbo.fatsmurf` (×2) | `perseus.fatsmurf` | Final join (cs, ls) | Schema correction — IF `goo_id` column exists |
| `NULL AS parent` | `NULL::INTEGER AS parent` | Anchor term | Explicit type for UNION compatibility |
| `SELECT * FROM (...) d` | Explicit 10-column projection | Outer SELECT | Replace wildcard with named columns |
| Missing CYCLE clause | `CYCLE child SET is_cycle USING path_array` | After CTE body | PostgreSQL 14+ cycle detection |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_jeremy_runs IS '...'` | Post-CREATE | Constitution Article VI |
| `goo.tree_scope_key/left/right` | Verify column names on DEV | Recursive branch 2 | May not exist — P0 blocker |
| `fatsmurf.goo_id` | Verify column name on DEV | Final join (cs, ls) | May not exist — P0 blocker |

---

## AWS SCT Assessment

AWS SCT output (`12.perseus.vw_jeremy_runs.sql`) key characteristics:
- `WITH RECURSIVE` correctly added — ✅
- Schema `perseus_hermes.*` for hermes objects — correct FDW schema name (confirm at deployment)
- Schema `perseus_dbo.*` for local objects — WRONG (should be `perseus.*`)
- **Six [9997 - Severity HIGH]** errors flagged for: `tree_scope_key`, `tree_left_key`, `tree_right_key` (×2 each), `goo_id` (×2) — columns SCT cannot resolve
- No `COMMENT ON VIEW` — missing
- `SELECT *` in outer query retained — P2-01

**SCT reliability score: 3/10**
The recursive CTE structure and FDW schema name are handled. However, six HIGH severity unresolved column references make this the lowest-quality SCT output in the entire view batch. Manual resolution is required for all six flagged columns before the view is deployable.

---

## Proposed PostgreSQL DDL (Minimal — Pending Blocker Resolution)

**This DDL is provided as a starting point only. It CANNOT be deployed until all three P0 blockers are resolved (hermes FDW, goo nested set columns, fatsmurf.goo_id).**

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_jeremy_runs
-- DEPRECATION CANDIDATE: Person-named view ('Jeremy Runs') — confirm active usage
-- with Pierre Ribeiro before investing refactoring effort.
--
-- DEPLOYMENT BLOCKED BY:
--   1. hermes FDW server not yet configured
--   2. goo.tree_scope_key/tree_left_key/tree_right_key — verify existence on DEV
--   3. fatsmurf.goo_id — verify existence on DEV
--
-- Description: Fermentation run report with goo hierarchy traversal. Uses a
--              three-branch recursive CTE ('tree') to traverse:
--              (1) Anchor: goo materials with hermes runs (via hermes.run FDW)
--              (2) Recursive: goo nested-set subtree (tree_scope/left/right keys)
--              (3) Recursive: goo_relationship edges
--              Final aggregation identifies cell harvest (smurf_id=23) and
--              liquid separation (smurf_id=25) steps per run, filtered to runs
--              with at least one such step.
--
-- Depends on:  perseus.goo (base table ✅)
--              perseus.goo_relationship (Wave 0 view ⚠️ FDW-blocked for 3rd branch)
--              perseus.fatsmurf (base table ✅ — IF goo_id column exists)
--              perseus.goo_type (base table ✅)
--              hermes.run (FDW ⚠️ — hermes server connection required)
--              hermes.run_condition_value (FDW ⚠️)
-- Blocks:      None
-- Wave:        Wave 1 (BLOCKED until hermes FDW live)
-- T-SQL ref:   dbo.vw_jeremy_runs
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

-- PREREQUISITE VALIDATION QUERIES (run on DEV before writing final DDL):
-- 1. SELECT column_name FROM information_schema.columns
--    WHERE table_schema='perseus' AND table_name='goo'
--    AND column_name IN ('tree_scope_key','tree_left_key','tree_right_key');
--    -- Must return 3 rows; if 0 rows, nested-set branch is undeployable.
--
-- 2. SELECT column_name FROM information_schema.columns
--    WHERE table_schema='perseus' AND table_name='fatsmurf'
--    AND column_name = 'goo_id';
--    -- Must return 1 row; if 0 rows, fatsmurf join is undeployable.
--
-- 3. SELECT nspname FROM pg_namespace WHERE nspname LIKE '%hermes%';
--    -- Confirm the hermes FDW schema name.

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

    -- Anchor: goo materials with hermes fermentation runs
    SELECT
        g.id                    AS starting_point,
        NULL::INTEGER           AS parent,
        g.id                    AS child
    FROM perseus.goo AS g
    JOIN hermes.run AS r              -- ⚠️ FDW: confirm schema name
        ON r.resultant_material = g.uid

    UNION ALL

    -- Recursive Branch 2: Nested-set subtree traversal
    -- ⚠️ VERIFY: goo.tree_scope_key, goo.tree_left_key, goo.tree_right_key must exist
    SELECT
        r.starting_point,
        g.id,
        c.id                    AS child
    FROM perseus.goo AS g
    JOIN perseus.goo AS c
        ON c.tree_scope_key = g.tree_scope_key     -- ⚠️ Column may not exist
       AND c.tree_left_key > g.tree_left_key        -- ⚠️ Column may not exist
       AND c.tree_right_key < g.tree_right_key      -- ⚠️ Column may not exist
    JOIN tree AS r
        ON g.id = r.child

    UNION ALL

    -- Recursive Branch 3: goo_relationship edge traversal
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
-- Cycle detection (PostgreSQL 14+)
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
FROM hermes.run AS r              -- ⚠️ FDW: confirm schema name
JOIN perseus.goo AS g
    ON r.resultant_material = g.uid
JOIN tree AS t
    ON g.id = t.starting_point
LEFT JOIN hermes.run_condition_value AS rcv    -- ⚠️ FDW
    ON rcv.run_id = r.id AND rcv.master_condition_id = 65
LEFT JOIN perseus.goo AS i
    ON i.uid = r.feedstock_material
LEFT JOIN perseus.goo_type AS gt
    ON gt.id = i.goo_type_id
LEFT JOIN perseus.fatsmurf AS cs
    ON t.child = cs.goo_id       -- ⚠️ Column may not exist in fatsmurf
   AND cs.smurf_id = 23
LEFT JOIN perseus.fatsmurf AS ls
    ON t.child = ls.goo_id       -- ⚠️ Column may not exist in fatsmurf
   AND ls.smurf_id = 25
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
HAVING MIN(cs.id) IS NOT NULL OR MIN(ls.id) IS NOT NULL;

-- Documentation
COMMENT ON VIEW perseus.vw_jeremy_runs IS
    'DEPRECATION CANDIDATE: Person-named view (''Jeremy Runs''). Confirm active usage. '
    'DEPLOYMENT BLOCKED: Requires hermes FDW server AND goo nested-set columns '
    '(tree_scope_key/left/right) AND fatsmurf.goo_id — verify all on DEV first. '
    'Recursive CTE traverses goo hierarchy (nested sets + relationships) for '
    'hermes fermentation runs. Reports cell harvest (smurf_id=23) and liquid '
    'separation (smurf_id=25) process steps per run. '
    'Depends on: goo, fatsmurf, goo_type (base tables), goo_relationship (Wave 0 view), '
    'hermes.run, hermes.run_condition_value (FDW tables). '
    'T-SQL source: dbo.vw_jeremy_runs | Migration task T038.';
```

**Note:** The `HAVING` clause replaces the outer `WHERE cell_harvest_id IS NOT NULL OR liquid_separation_id IS NOT NULL` subquery wrapping from the T-SQL original. This is equivalent but avoids the unnecessary subquery wrapper.

---

## Quality Score Estimate

*Score reflects the proposed DDL assuming all P0 blockers are resolved.*

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 7/10 | WITH RECURSIVE, CYCLE clause, HAVING — valid PostgreSQL 17. Score reduced to 7 because three P0 blockers (nested-set columns, fatsmurf.goo_id, hermes FDW) must be resolved before this can be validated. Cannot confirm correctness without DEV verification. |
| Logic Preservation | 7/10 | Three-branch CTE, GROUP BY/HAVING, FDW joins — structurally preserved. HAVING replaces outer subquery WHERE (semantically equivalent). Score reduced: nested-set column names unverified, `goo_id` column unverified. |
| Performance | 5/10 | Three-branch recursive CTE with GROUP BY aggregation and FDW tables. FDW latency for hermes.run and hermes.run_condition_value is the primary concern. Nested-set traversal can be expensive for large goo hierarchies. Post-deployment performance benchmarking is mandatory. |
| Maintainability | 6/10 | COMMENT ON VIEW documents blockers and deprecation flag. Inline `⚠️` warnings on unverified columns. Person-named view is an inherent maintainability concern regardless of DDL quality. |
| Security | 8.5/10 | Schema-qualified (subject to FDW schema confirmation), no dynamic SQL. FDW security depends on hermes server credentials configuration. |
| **Overall** | **6.7/10** | Below STAGING gate (7.0) until all P0 blockers are resolved. Do NOT deploy to STAGING until blockers are cleared and scores reassessed. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 3-4 hours (if not deprecated and blockers resolved) |
| Risk | High |
| Blocker | (1) hermes FDW live, (2) goo tree columns verified, (3) fatsmurf.goo_id verified, (4) deprecation decision |

**Effort breakdown:**
- 0.5 h — Deprecation decision + column verification queries on DEV (`\d perseus.goo`, `\d perseus.fatsmurf`)
- 0.5 h — hermes FDW schema name confirmation + schema corrections
- 1.0 h — Write final DDL with verified column names, CYCLE clause, HAVING
- 0.5 h — COMMENT ON VIEW, format DDL, resolve `⚠️` placeholders
- 0.5 h — Syntax validation with `psql` (requires FDW live)
- 0.5 h — EXPLAIN ANALYZE, FDW latency measurement, quality score update

**Risk: High** — Multiple hard blockers. Do not start refactoring until blockers 1-4 are resolved. This is the highest-risk view in the T038 batch.

**Recommended approach:** Schedule after all 19 non-FDW views are deployed. Treat as a separate sub-task once hermes FDW infrastructure is configured.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
