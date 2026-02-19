# Analysis: hermes_run (T037)

**Project**: Perseus Database Migration (SQL Server -> PostgreSQL 17)
**Task**: T037
**Analyst**: database-expert (manual)
**Date**: 2026-02-19
**Branch**: us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.hermes_run` |
| PostgreSQL name | `perseus.hermes_run` |
| Type | Standard View (single SELECT with LEFT JOINs and WHERE filter) |
| Priority | P1 (High) — FDW makes this effectively undeployable until hermes server is live |
| Complexity | 6/10 |
| Wave | Wave 0 (depends only on base tables and one FDW table — no view dependencies) |
| Depends on | `hermes.run` (FDW, primary source), `perseus.goo`, `perseus.container` |
| Blocks | Nothing directly — `vw_jeremy_runs` (P3) does not depend on this view |
| FDW dependency | `hermes.run` — entire body of the view depends on this table (FDW server not yet configured) |

---

## Source Code Review

### T-SQL Original (`source/original/sqlserver/10.create-view/7.perseus.dbo.hermes_run.sql`)

```sql
USE [perseus]
GO

CREATE VIEW hermes_run AS
SELECT
r.experiment_id,
r.local_id AS run_id,
r.description,
r.created_on,
r.strain,
r.max_yield AS yield,
r.max_titer AS titer,
rg.id AS result_goo_id,
ig.id AS feedstock_goo_id,
c.id AS container_id,
r.start_time AS run_on,
r.stop_time AS duration
FROM hermes.run r
LEFT JOIN goo rg ON 'm'+CONVERT(VARCHAR(10), rg.id) = r.resultant_material
LEFT JOIN goo ig ON 'm'+CONVERT(VARCHAR(10), ig.id) = r.feedstock_material
LEFT JOIN container c ON c.uid = r.tank
WHERE (ISNULL(r.feedstock_material,'') != '' OR ISNULL(r.resultant_material,'') != '')
AND ISNULL(r.feedstock_material,'') != ISNULL(r.resultant_material,'')
```

### AWS SCT Output (`source/original/pgsql-aws-sct-converted/15.create-view/7.perseus.hermes_run.sql`)

```sql
CREATE OR REPLACE  VIEW perseus_dbo.hermes_run
    (experiment_id, run_id, description, created_on, strain, yield, titer,
     result_goo_id, feedstock_goo_id, container_id, run_on, duration) AS
SELECT
    r.experiment_id, r.local_id AS run_id, r.description, r.created_on, r.strain,
    r.max_yield AS yield, r.max_titer AS titer, rg.id AS result_goo_id,
    ig.id AS feedstock_goo_id, c.id AS container_id, r.start_time AS run_on,
    r.stop_time AS duration
    FROM perseus_hermes.run AS r
    LEFT OUTER JOIN perseus_dbo.goo AS rg
        ON ('m' || CAST (rg.id AS VARCHAR(10)))::CITEXT = r.resultant_material
    LEFT OUTER JOIN perseus_dbo.goo AS ig
        ON ('m' || CAST (ig.id AS VARCHAR(10)))::CITEXT = r.feedstock_material
    LEFT OUTER JOIN perseus_dbo.container AS c
        ON c.uid = r.tank
    WHERE (COALESCE(r.feedstock_material, '')::CITEXT != '' OR
           COALESCE(r.resultant_material, '')::CITEXT != '')
      AND COALESCE(r.feedstock_material, '')::CITEXT != COALESCE(r.resultant_material, '')::CITEXT;
```

---

## Issue Register

### P0 Issues — Blocks ALL Testing and Deployment

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P0-1 | Schema `perseus_dbo` is incorrect — all local objects must use schema `perseus`; FDW objects use schema `hermes` | View header, all `FROM` / `JOIN` clauses | View cannot deploy; all object references fail to resolve |
| P0-2 | SCT schema for the hermes FDW table is `perseus_hermes.run` — incorrect; deployed FDW schema is `hermes` | `FROM perseus_hermes.run AS r` | Primary source table fails to resolve even when FDW server is live |
| P0-3 | `hermes.run` FDW server (`hermes_server`) not yet configured — entire view body queries from this table | All SELECT columns and all JOIN conditions | View is completely undeployable until `CREATE SERVER hermes_server ...` and `CREATE USER MAPPING ...` are executed with valid credentials |

**P0-3 Detail**: Unlike `goo_relationship`, which has a partial-deployment workaround (two-branch version without FDW), `hermes_run` has no partial deployment option. Every column selected and every join performed references `hermes.run` as the primary driving table. The view cannot be created at all until FDW is live.

### P1 Issues — Must Fix Before PROD Deployment

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P1-1 | `::CITEXT` cast applied to JOIN conditions and WHERE predicates — changes comparison from case-sensitive to case-insensitive | All three `::CITEXT` usages in SCT output | Material UIDs (`m12345`) are case-sensitive in the original system. CITEXT changes the JOIN matching semantics silently — a UID `M12345` would incorrectly match `m12345` with CITEXT, producing wrong join results. |
| P1-2 | `r.stop_time AS duration` — column aliased as `duration` but `stop_time` in `hermes.run` is `NUMERIC(10,2)` (confirmed in deployed `hermes.run` DDL), not a time duration type | `r.stop_time AS duration` | The alias `duration` implies a time interval but the underlying value is a floating-point number (presumably hours or minutes of run duration, not a TIMESTAMP or INTERVAL). This creates a semantic contract mismatch for consumers of the view. No cast error will occur, but downstream code expecting an INTERVAL or TIMESTAMP will behave incorrectly. Flag for business logic validation. |
| P1-3 | `'m' + CONVERT(VARCHAR(10), rg.id)` JOIN condition — builds material UID like `m12345` to match `hermes.run.resultant_material`; this pattern embeds business logic (the `m` prefix convention) directly in the join condition | Both LEFT JOIN conditions | If the `m` prefix convention ever changes, or if some goo records use a different UID format, the join silently returns NULL (no match). Additionally, `VARCHAR(10)` truncates goo IDs >= 10 digits (> 999,999,999) — extremely unlikely given current data volumes but worth noting. |
| P1-4 | WHERE clause logic: `ISNULL(x,'') != ''` combined with `ISNULL(x,'') != ISNULL(y,'')` — the first condition filters for runs that have at least one material; the second filters for runs where feedstock != resultant. The interaction of these two conditions must be preserved exactly. | Full WHERE clause | Any simplification risk: if the two COALESCE conditions are reordered or incorrectly combined, runs with one NULL material (feedstock only or resultant only) could be included or excluded incorrectly. |

**P1-2 Investigation — `stop_time` column type in `hermes.run`**:

From the deployed `hermes.run` foreign table DDL:
```
stop_time NUMERIC(10,2)
```
And `start_time TIMESTAMP`. The view aliases `r.start_time AS run_on` (TIMESTAMP -> fine) and `r.stop_time AS duration` (NUMERIC -> aliased as duration). In the SQL Server original, `stop_time` on the `hermes.run` linked server table appears to be a numeric value representing elapsed time (likely hours or minutes), not an actual TIMESTAMP. The alias `duration` is semantically accurate for the numeric value, but the data type should be documented for view consumers.

### P2 Issues — Fix Before STAGING Deployment

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P2-1 | `LEFT OUTER JOIN` in SCT vs `LEFT JOIN` in T-SQL — functionally identical but `LEFT OUTER JOIN` is verbose | All three join clauses | No behavioral change; style preference per constitution (use `LEFT JOIN`, not `LEFT OUTER JOIN`) |
| P2-2 | `CAST(rg.id AS VARCHAR(10))` — SCT used `VARCHAR(10)` matching the T-SQL `CONVERT(VARCHAR(10), rg.id)`. The `goo.id` column is INTEGER; `::TEXT` is sufficient and clearer | `('m' || CAST(rg.id AS VARCHAR(10)))` | VARCHAR(10) is wider than needed for 32-bit INT (max 10 digits) but produces correct results. Using `rg.id::TEXT` is idiomatic PostgreSQL. |
| P2-3 | No `CREATE OR REPLACE` idempotency in original T-SQL | `CREATE VIEW hermes_run` | Deployment script must use `CREATE OR REPLACE VIEW` for safe re-runs |
| P2-4 | All SELECT columns on one line in SCT output — no formatting | SCT SELECT list | Readability and maintainability issue; multi-line formatting required per constitution standard |

### P3 Issues — Track for Future Improvement

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P3-1 | No `SECURITY INVOKER` declaration | View header | PostgreSQL defaults to SECURITY INVOKER — should be explicit per constitution |
| P3-2 | No comments or header documentation | Entire view | Does not conform to project maintainability standard |
| P3-3 | `goo.id` is INTEGER — `rg.id::TEXT` will never be wider than 10 characters for any foreseeable goo dataset — but the `m` + id construction should be documented as a business convention | JOIN conditions | Future maintainers need to understand why the join uses string construction rather than a direct key |
| P3-4 | No index on `goo.uid` confirmed — the LEFT JOINs on `rg.id::TEXT = r.resultant_material` require sequential scan on `goo` unless an index exists | Both LEFT JOIN conditions on `goo` | Performance concern for large `hermes.run` datasets. Check `CREATE INDEX` files for `ix_goo_uid` or equivalent. |
| P3-5 | `duration` column exposes a NUMERIC type labeled as duration — consumer documentation needed | `r.stop_time AS duration` in SELECT | Without documentation, consumers may misinterpret the unit (seconds? minutes? hours?) or try to use it as a TIMESTAMP |

---

## T-SQL to PostgreSQL Transformations Required

| # | T-SQL Pattern | PostgreSQL Equivalent | Applied In | Notes |
|---|---------------|----------------------|------------|-------|
| 1 | `[dbo].` schema prefix | `perseus.` | `goo`, `container` references | SCT used `perseus_dbo` — correct to `perseus` |
| 2 | `[hermes].` schema prefix | `hermes.` | `hermes.run` FDW reference | SCT used `perseus_hermes` — correct to `hermes` |
| 3 | `'m' + CONVERT(VARCHAR(10), rg.id)` | `'m' \|\| rg.id::TEXT` | Both LEFT JOIN conditions | `+` concat -> `\|\|`; `CONVERT(VARCHAR(10), x)` -> `x::TEXT`. SCT applied `\|\|` and `CAST` correctly but added wrong CITEXT cast |
| 4 | `LEFT JOIN` | `LEFT JOIN` (not `LEFT OUTER JOIN`) | All three join clauses | Functionally identical; `LEFT OUTER JOIN` is verbose. Per constitution, use concise form |
| 5 | `ISNULL(x, y)` | `COALESCE(x, y)` | WHERE clause | SCT applied correctly; remove CITEXT cast from result |
| 6 | `::CITEXT` cast on TEXT comparisons | Remove — use plain `TEXT` comparison | All three SCT CITEXT usages (2 JOIN conditions, WHERE clause) | CITEXT changes case-sensitivity; original T-SQL is case-sensitive. Removal restores correct semantics. |
| 7 | `CREATE VIEW` (no idempotency) | `CREATE OR REPLACE VIEW` | View header | Enables safe re-deployment |
| 8 | Unformatted single-line SELECT | Multi-line formatted SELECT | Entire SELECT list | Constitution maintainability requirement |

---

## AWS SCT Assessment

### What SCT Got Right

- Applied `COALESCE` for all `ISNULL(x, y)` occurrences in the WHERE clause.
- Converted `+` string concatenation to `||` in both JOIN conditions.
- Converted `CONVERT(VARCHAR(10), x)` to `CAST(x AS VARCHAR(10))`.
- Added explicit column list to the view header — good practice.
- Preserved all column aliases (`run_id`, `yield`, `titer`, `result_goo_id`, `feedstock_goo_id`, `container_id`, `run_on`, `duration`).
- Preserved LEFT JOIN semantics (LEFT OUTER JOIN is equivalent).
- Applied `CREATE OR REPLACE VIEW` idiom.

### What SCT Got Wrong / Missed

- **Schema naming (systematic error)**: Used `perseus_dbo` for local objects and `perseus_hermes` for the hermes FDW table. Both are wrong — correct schemas are `perseus` and `hermes` respectively.
- **CITEXT cast (logic error — HIGH severity)**: Applied `::CITEXT` to every string comparison in both JOIN conditions and the WHERE clause. This is a pervasive logic error that changes case-sensitivity for all material UID matching. In a system where UIDs like `m12345` are case-sensitive identifiers, this silently corrupts join semantics.
- **`stop_time` type annotation missing**: SCT did not flag the semantic mismatch between the `stop_time` column name (implies a point in time) and the `duration` alias (implies elapsed time). This warrants a business logic comment.
- **JOIN index analysis absent**: SCT did not evaluate whether indexes support the string-construction JOIN conditions (`'m' || id::TEXT = resultant_material`).
- **No FDW blocking annotation**: SCT did not mark the view as undeployable without the hermes FDW server.

### SCT Reliability Score: 4/10

The pervasive CITEXT logic error across all three comparison points is the disqualifying issue — it would produce incorrect join results in production for any material UIDs with mixed case. The schema errors are systematic and predictable. The structural transformation of the core logic (COALESCE, ||, CAST) was performed correctly. The overall SCT output requires substantial manual correction before it is safe to deploy.

---

## FDW Dependency Analysis

### Deployment Blocker

The entire `hermes_run` view body drives from `hermes.run` as the primary table in the `FROM` clause. Unlike `goo_relationship`, there is no subset of the query that can be deployed without the FDW table. PostgreSQL validates all foreign table references at `CREATE VIEW` time — if `hermes.run` is inaccessible (FDW server not configured), the view creation fails with an error.

**Full deployment is blocked until:**
1. `CREATE EXTENSION IF NOT EXISTS postgres_fdw;` is executed.
2. `CREATE SERVER hermes_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '...', dbname 'hermes', port '5432');` is executed with real credentials.
3. `CREATE USER MAPPING FOR ... SERVER hermes_server OPTIONS (user '...', password '...');` is executed.
4. The `hermes.run` foreign table exists (already defined in `hermes_run.sql` — deploys after server is live).

**Status**: `hermes_fdw_setup.sql` exists with the server creation commented out pending credentials. This is a P1 infrastructure task for the DBA/infra team.

### Partial Deployment Strategy (Without FDW)

**There is no partial deployment option for `hermes_run`**. The view cannot be created in any useful form without `hermes.run`. The only alternative would be to create a stub view against local tables, which would not represent the actual business logic and could mislead consumers.

**Recommended approach**: Do not deploy `hermes_run` until FDW is live. Document the blocking status in the deployment runbook.

### What Can Be Tested Without FDW

- SQL syntax validation can be performed by parsing the DDL against a schema that includes a mock `hermes.run` table (created as a local temporary or regular table with the same column structure).
- Business logic review of the WHERE clause conditions can be validated in isolation.
- The `'m' || rg.id::TEXT` join construction can be validated against `perseus.goo` independently.

### Mock Schema Test Pattern

```sql
-- For syntax validation only (not production use):
CREATE SCHEMA IF NOT EXISTS hermes;
CREATE TABLE IF NOT EXISTS hermes.run_mock (
    id               INTEGER,
    experiment_id    INTEGER,
    local_id         INTEGER,
    description      VARCHAR(255),
    created_on       TIMESTAMP,
    strain           VARCHAR(30),
    resultant_material TEXT,
    feedstock_material VARCHAR(50),
    start_time       TIMESTAMP,
    stop_time        NUMERIC(10,2),
    max_yield        NUMERIC(15,5),
    max_titer        NUMERIC(15,5),
    tank             VARCHAR(20)
);
-- Rename temporarily to test view creation syntax
ALTER TABLE hermes.run_mock RENAME TO run;
-- Run CREATE VIEW...
-- After validation, rename back and drop
ALTER TABLE hermes.run RENAME TO run_mock;
DROP TABLE hermes.run_mock;
```

---

## Dependencies Verified

| Object | Type | Schema | Status | Notes |
|--------|------|--------|--------|-------|
| `hermes.run` | Foreign table | `hermes` | DDL defined; FDW server not configured | Primary source — 90 columns; `feedstock_material VARCHAR(50)`, `resultant_material TEXT`, `stop_time NUMERIC(10,2)`, `start_time TIMESTAMP`, `tank VARCHAR(20)` all confirmed |
| `goo` | Base table | `perseus` | Deployed (DDL file present) | `id INTEGER`, `uid VARCHAR(50)` confirmed — JOIN on `'m' \|\| rg.id::TEXT = r.resultant_material` is valid |
| `container` | Base table | `perseus` | Deployed (DDL file present) | `id INTEGER`, `uid VARCHAR(50)` confirmed — JOIN on `c.uid = r.tank` is valid (`tank VARCHAR(20)` matches `uid VARCHAR(50)`) |

### Type Compatibility Analysis

| Join Condition | Left Type | Right Type | Compatible? | Notes |
|---------------|-----------|------------|-------------|-------|
| `'m' \|\| rg.id::TEXT = r.resultant_material` | `TEXT` (constructed) | `TEXT` | Yes | Both TEXT — implicit cast handled by PostgreSQL |
| `'m' \|\| ig.id::TEXT = r.feedstock_material` | `TEXT` (constructed) | `VARCHAR(50)` | Yes | VARCHAR is TEXT with length constraint — compatible |
| `c.uid = r.tank` | `VARCHAR(50)` | `VARCHAR(20)` | Yes | VARCHAR comparison — compatible; tank values fit within uid width |
| `COALESCE(r.feedstock_material, '') != ''` | `VARCHAR(50)` | `TEXT` | Yes | PostgreSQL coerces VARCHAR to TEXT for comparison |
| `COALESCE(r.feedstock_material, '') != COALESCE(r.resultant_material, '')` | `VARCHAR(50)` | `TEXT` | Yes | Comparable types |

---

## Proposed PostgreSQL DDL

**NOTE**: This view can only be deployed when the `hermes_server` FDW connection is live.

**Dialect**: PostgreSQL 17
**Schema**: `perseus` (view), `hermes` (FDW source table)
**File**: `source/building/pgsql/refactored/15.create-view/hermes_run.sql`

```sql
-- =============================================================================
-- View: perseus.hermes_run
-- Source: SQL Server [dbo].[hermes_run] (10.create-view/7.perseus.dbo.hermes_run.sql)
-- Type: Standard View (single SELECT, 3 LEFT JOINs, compound WHERE filter)
-- Priority: P1 (High) — FDW-blocked
-- Wave: Wave 0 (no view dependencies)
-- Depends on: hermes.run (FDW via hermes_server — REQUIRED before deployment)
--             perseus.goo, perseus.container (local — deployed)
-- Blocks: Nothing directly. vw_jeremy_runs depends on goo_relationship, not this view.
-- Description: Exposes hermes fermentation run records enriched with local material
--              and container references. Maps hermes run UID strings (e.g. 'm12345')
--              to goo.id integers for the feedstock (input) and resultant (output)
--              materials, and resolves the tank UID to a container record.
--              Only runs with at least one material (feedstock or resultant) are
--              returned, and runs where feedstock == resultant are excluded.
-- FDW dependency: hermes_server must be configured before this view can be created.
--   See: source/building/pgsql/refactored/14.create-table/hermes_fdw_setup.sql
-- Column notes:
--   run_on   -> r.start_time  (TIMESTAMP — when the run started)
--   duration -> r.stop_time   (NUMERIC(10,2) — elapsed run duration, NOT a stop timestamp)
-- Author: migration US1-critical-views / T037
-- Date: 2026-02-19
-- =============================================================================

-- DEPLOYMENT GATE: Verify hermes FDW server is live before running.
-- SELECT * FROM pg_foreign_server WHERE srvname = 'hermes_server';
-- Expected: one row returned. If no rows, configure FDW first.

CREATE OR REPLACE VIEW perseus.hermes_run
    (experiment_id, run_id, description, created_on, strain, yield, titer,
     result_goo_id, feedstock_goo_id, container_id, run_on, duration)
AS
SELECT
    r.experiment_id,
    r.local_id                      AS run_id,
    r.description,
    r.created_on,
    r.strain,
    r.max_yield                     AS yield,
    r.max_titer                     AS titer,
    rg.id                           AS result_goo_id,
    ig.id                           AS feedstock_goo_id,
    c.id                            AS container_id,
    r.start_time                    AS run_on,
    -- stop_time is NUMERIC(10,2), representing elapsed run duration.
    -- It is NOT a stop timestamp. Aliased 'duration' per original view contract.
    r.stop_time                     AS duration
FROM hermes.run AS r
-- Resolve resultant_material UID (e.g. 'm12345') to goo.id.
-- The 'm' prefix is a business convention for material UIDs in hermes.
LEFT JOIN perseus.goo AS rg
    ON ('m' || rg.id::TEXT) = r.resultant_material
-- Resolve feedstock_material UID (e.g. 'm12345') to goo.id.
LEFT JOIN perseus.goo AS ig
    ON ('m' || ig.id::TEXT) = r.feedstock_material
-- Resolve tank UID to container record.
LEFT JOIN perseus.container AS c
    ON c.uid = r.tank
WHERE
    -- Include only runs with at least one material reference (feedstock OR resultant).
    (COALESCE(r.feedstock_material, '') != ''
     OR COALESCE(r.resultant_material, '') != '')
    -- Exclude runs where feedstock and resultant are the same material
    -- (no meaningful input-to-output transformation occurred).
    AND COALESCE(r.feedstock_material, '') != COALESCE(r.resultant_material, '');

COMMENT ON VIEW perseus.hermes_run IS
    'Hermes fermentation run records enriched with local material and container references. '
    'Maps hermes UID strings (m + goo.id) to perseus.goo integer IDs for feedstock/resultant. '
    'Filters: runs with at least one material, feedstock != resultant. '
    'Column duration = r.stop_time (NUMERIC elapsed time, not a stop timestamp). '
    'P1 - Wave 0. FDW-blocked: requires hermes_server FDW connection. '
    'See hermes_fdw_setup.sql for server configuration.';
```

### Key DDL Decisions

| Decision | Rationale |
|----------|-----------|
| Schema `perseus` on view and local tables | Corrects SCT `perseus_dbo` error; schema-qualifies per constitution principle 7 |
| Schema `hermes` on FDW table | Corrects SCT `perseus_hermes` error; matches deployed `hermes.run` foreign table definition |
| Removed all `::CITEXT` casts | All three SCT CITEXT usages removed. Original T-SQL uses case-sensitive string comparison. CITEXT would change join matching and WHERE filter semantics silently. |
| `rg.id::TEXT` instead of `CAST(rg.id AS VARCHAR(10))` | Idiomatic PostgreSQL. `goo.id` is INTEGER; `::TEXT` is sufficient and produces identical results without the unnecessary VARCHAR length constraint. |
| `LEFT JOIN` not `LEFT OUTER JOIN` | Concise form per constitution preference. Semantically identical. |
| `COALESCE(x, '') != ''` without CITEXT | Preserves original case-sensitive comparison. The CITEXT removal changes `COALESCE(x,'')::CITEXT != ''` to `COALESCE(x, '') != ''` — functionally identical for this comparison since `''` has no case. The case-sensitivity concern applies to the material UID comparisons. |
| Inline comment on `duration` column | Documents the type mismatch between the `stop_time` NUMERIC source and the `duration` alias name. Critical for consumer understanding. |
| Deployment gate comment | Prevents accidental deployment before FDW is live; references the FDW setup file. |
| `CREATE OR REPLACE VIEW` | Idempotent deployment; enables safe re-deployment once FDW is live. |
| Column list in view header | Explicit interface contract; makes column names independent of aliases in SELECT. |
| `COMMENT ON VIEW` | Documents purpose, FDW dependency, duration column type, wave, and priority. |

---

## Performance Considerations

### JOIN Condition on String Construction

The LEFT JOIN conditions `('m' || rg.id::TEXT) = r.resultant_material` and `('m' || ig.id::TEXT) = r.feedstock_material` are non-sargable — PostgreSQL cannot use an index on `goo.id` to satisfy these joins because the left side applies a function (`||` concatenation and `::TEXT` cast) to the indexed column. This forces a sequential scan on `perseus.goo` for each row in `hermes.run`.

For the result set to be acceptable:
- If `hermes.run` is small (< 10,000 rows after WHERE filtering), a hash join with full `goo` scan completes quickly.
- If `hermes.run` grows large, a functional index on `('m' || id::TEXT)` on `goo` would make these joins indexable.

**Recommended index (if performance is a concern post-FDW activation)**:

```sql
-- Functional index to support hermes_run view JOIN conditions
CREATE INDEX ix_goo_m_uid ON perseus.goo (('m' || id::TEXT));
```

This index allows PostgreSQL to use an index scan on `goo` when joining on `('m' || rg.id::TEXT) = r.resultant_material`.

### WHERE Clause Performance

The compound WHERE clause uses two COALESCE conditions:
1. `COALESCE(feedstock_material, '') != ''` OR `COALESCE(resultant_material, '') != ''` — filters for runs with at least one material
2. `COALESCE(feedstock_material, '') != COALESCE(resultant_material, '')` — filters out same-material runs

If `hermes.run` has indexes on `feedstock_material` or `resultant_material`, these conditions may use index scans. However, since the FDW table is remote, index pushdown depends on the FDW statistics and the remote PostgreSQL server's query plan. Monitor with `EXPLAIN ANALYZE` after FDW activation.

### FDW Fetch Size Tuning

For the `hermes_server` FDW, set an appropriate `fetch_size` in the server options based on the expected row count of `hermes.run`:

```sql
-- Tune based on actual hermes.run row count:
ALTER SERVER hermes_server OPTIONS (ADD fetch_size '1000');
-- Or for large tables (> 100k rows):
ALTER SERVER hermes_server OPTIONS (ADD fetch_size '5000');
```

---

## Quality Score Estimate

This score reflects the **proposed PostgreSQL DDL** above (post-correction).

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9/10 | Valid PostgreSQL 17 syntax. COALESCE without CITEXT, `::TEXT` cast, `LEFT JOIN`. Conditional on FDW server availability for full parse validation. |
| Logic Preservation | 9/10 | All WHERE conditions semantically identical to T-SQL original. CITEXT removal restores correct case-sensitive comparison. `stop_time AS duration` preserved with type documented. `'m' \|\| id::TEXT` join construction equivalent to `'m' + CONVERT(VARCHAR(10), id)`. |
| Performance | 7/10 | Non-sargable JOIN conditions (`'m' \|\| id::TEXT`) force goo table scan. Acceptable for current data volumes; functional index recommendation provided for growth scenario. FDW performance externally controlled by hermes server and fetch_size configuration. |
| Maintainability | 9/10 | Header documentation, inline comments on JOIN logic and duration type, COMMENT ON VIEW, deployment gate comment. Multi-line formatted SELECT list. snake_case, schema-qualified. |
| Security | 8/10 | Defaults to SECURITY INVOKER (correct). Schema-qualified references prevent search_path manipulation. No dynamic SQL, no injection vectors. FDW credentials must be managed securely (not in DDL files). -1 for not declaring SECURITY INVOKER explicitly. |
| **Overall** | **8.4/10** | Exceeds 7.0/10 minimum. Deployment gated by FDW infrastructure — no code issues blocking quality gate. P1 CITEXT errors resolved in proposed DDL. |

---

## Refactoring Effort Estimate

- **Effort**: 2.0 hours
  - 0.5h: Apply schema renames (`perseus_dbo` -> `perseus`, `perseus_hermes` -> `hermes`), remove all `::CITEXT` casts
  - 0.5h: Convert `CONVERT(VARCHAR(10), x)` -> `x::TEXT`, `LEFT OUTER JOIN` -> `LEFT JOIN`, format SELECT list
  - 0.5h: Add documentation header, COMMENT ON VIEW, deployment gate comment, duration type annotation
  - 0.5h: FDW dependency documentation, performance index recommendation, mock schema test plan
- **Risk**: Medium
  - High (infrastructure): FDW server is the binding constraint — view cannot be deployed or fully tested until hermes credentials are available. This is outside the migration team's control.
  - Low (code): Once FDW is live, the view logic is straightforward. All transformations are mechanical and well-understood. The CITEXT removal is the only meaningful logic change.
  - Medium (performance): The `'m' || id::TEXT` JOIN pattern is non-sargable. If the hermes.run table is large in production, query plans must be validated with `EXPLAIN ANALYZE` post-deployment.
- **Testing gate**: After refactoring, validate:
  1. Syntax validates against mock hermes.run table (see mock schema test pattern in FDW section)
  2. Once FDW live: view creates without error
  3. Row count matches expected hermes run data (confirm with hermes DBA)
  4. `result_goo_id` and `feedstock_goo_id` resolve correctly for known run records
  5. `WHERE` filter: no rows where `feedstock_material = resultant_material` and no rows where both materials are NULL
  6. `duration` column values are NUMERIC and match expected elapsed time values from hermes source

---

*Generated by T037 | Branch: us1-critical-views | 2026-02-19*
