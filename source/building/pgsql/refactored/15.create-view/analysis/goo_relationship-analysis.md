# Analysis: goo_relationship (T037)

**Project**: Perseus Database Migration (SQL Server -> PostgreSQL 17)
**Task**: T037
**Analyst**: database-expert (manual)
**Date**: 2026-02-19
**Branch**: us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.goo_relationship` |
| PostgreSQL name | `perseus.goo_relationship` |
| Type | Standard View (3-branch UNION) |
| Priority | P1 (High) |
| Complexity | 6/10 |
| Wave | Wave 0 (depends only on base tables and one FDW table) |
| Depends on | `perseus.goo`, `perseus.fatsmurf`, `hermes.run` (FDW) |
| Blocks | `perseus.vw_jeremy_runs` (P3) |
| FDW dependency | `hermes.run` — third UNION branch only (FDW server not yet configured) |

---

## Source Code Review

### T-SQL Original (`source/original/sqlserver/10.create-view/6.perseus.dbo.goo_relationship.sql`)

```sql
USE [perseus]
GO

CREATE VIEW goo_relationship AS
SELECT id AS parent, merged_into AS child
FROM goo
WHERE merged_into IS NOT NULL
UNION
SELECT p.id, c.id
FROM goo p
JOIN fatsmurf fs ON fs.goo_id = p.id
JOIN goo c ON c.source_process_id = fs.id
UNION
SELECT i.id, o.id
FROM hermes.run r
JOIN goo i ON i.uid = r.feedstock_material
JOIN goo o ON o.uid = r.resultant_material
WHERE ISNULL(r.feedstock_material, '') != ISNULL(r.resultant_material, '')
```

### AWS SCT Output (`source/original/pgsql-aws-sct-converted/15.create-view/6.perseus.goo_relationship.sql`)

```sql
CREATE OR REPLACE VIEW perseus_dbo.goo_relationship (parent, child) AS
SELECT
    id AS parent, merged_into
    /*
    [9997 - Severity HIGH - Unable to resolve the object merged_into. Verify if
    the unresolved object is present in the database.]
    merged_into
    */
    AS child
    FROM perseus_dbo.goo
    WHERE merged_into
    /*
    [9997 - Severity HIGH - Unable to resolve the object merged_into.]
    merged_into
    */
    IS NOT NULL
UNION
SELECT
    p.id, c.id
    FROM perseus_dbo.goo AS p
    JOIN perseus_dbo.fatsmurf AS fs
        ON fs.goo_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object goo_id.]
        goo_id
        */
        = p.id
    JOIN perseus_dbo.goo AS c
        ON c.source_process_id
        /*
        [9997 - Severity HIGH - Unable to resolve the object source_process_id.]
        source_process_id
        */
        = fs.id
UNION
SELECT
    i.id, o.id
    FROM perseus_hermes.run AS r
    JOIN perseus_dbo.goo AS i ON i.uid = r.feedstock_material
    JOIN perseus_dbo.goo AS o ON o.uid = r.resultant_material
    WHERE COALESCE(r.feedstock_material, '')::CITEXT != COALESCE(r.resultant_material, '')::CITEXT;
```

---

## Issue Register

### P0 Issues — Blocks ALL Testing and Deployment

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P0-1 | Schema `perseus_dbo` is incorrect — all local objects must use schema `perseus`; FDW objects use schema `hermes` | View header, all `FROM` / `JOIN` clauses | View cannot deploy; all object references fail to resolve |
| P0-2 | SCT schema for the hermes FDW table is `perseus_hermes.run` — incorrect; deployed FDW schema is `hermes` | Third UNION branch `FROM perseus_hermes.run AS r` | Third branch fails to resolve even when FDW server is live |

**P0-1 Detail**: AWS SCT mechanically maps SQL Server `dbo` to `perseus_dbo` and `hermes` to `perseus_hermes`. The actual PostgreSQL target schema for all local objects is `perseus`, and the FDW schema for hermes tables is `hermes`. Every reference must be corrected before the view will parse.

**P0-2 Detail**: The deployed foreign table is `hermes.run` (confirmed in `source/building/pgsql/refactored/14.create-table/hermes_run.sql` — `CREATE FOREIGN TABLE IF NOT EXISTS hermes.run ...`). SCT emitted `perseus_hermes.run`, which does not correspond to any schema in the target environment.

### P1 Issues — Must Fix Before PROD Deployment

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P1-1 | `::CITEXT` cast in the third UNION WHERE clause is incorrect — plain `TEXT` comparison is sufficient and semantically correct | `WHERE COALESCE(r.feedstock_material, '')::CITEXT != COALESCE(r.resultant_material, '')::CITEXT` | CITEXT is case-insensitive; the original ISNULL comparison is case-sensitive. Using CITEXT silently changes comparison semantics. Material UIDs like `m12345` are case-sensitive in practice. |
| P1-2 | `goo.merged_into`, `fatsmurf.goo_id`, and `goo.source_process_id` — SCT raised 4 HIGH severity errors claiming these columns cannot be resolved | All three UNION branches | SCT failed to introspect the deployed table schema. Columns confirmed present in deployed DDL: `goo.merged_into` is NOT listed in `source/building/pgsql/refactored/14.create-table/goo.sql` — see missing-column investigation in Dependencies Verified section below |

**P1-2 Critical Investigation — Missing Columns in Deployed `goo` Table**:

The deployed `perseus.goo` table DDL (`source/building/pgsql/refactored/14.create-table/goo.sql`) contains 20 columns:
`id, name, description, added_on, added_by, original_volume, original_mass, goo_type_id, manufacturer_id, received_on, uid, project_id, container_id, workflow_step_id, updated_on, inserted_on, triton_task_id, recipe_id, recipe_part_id, catalog_label`

**Missing from deployed DDL:**
- `merged_into` — referenced in Branch 1 (`WHERE merged_into IS NOT NULL`)
- `source_process_id` — referenced in Branch 2 (`c.source_process_id = fs.id`)

**Missing from deployed fatsmurf DDL** (`source/building/pgsql/refactored/14.create-table/fatsmurf.sql`):
- `goo_id` — referenced in Branch 2 (`fs.goo_id = p.id`)

The deployed `fatsmurf` table has 18 columns: `id, smurf_id, recycled_bottoms_id, name, description, added_on, run_on, duration, added_by, themis_sample_id, uid, run_complete, container_id, organization_id, workflow_step_id, updated_on, inserted_on, triton_task_id` — `goo_id` is absent.

**This is a P1 deployment blocker for Branches 1 and 2, independent of the FDW issue**. SCT was correct to flag these columns as unresolved — they do not exist in the deployed table DDL. The original SQL Server schema must have had these columns. Root cause: column name drift during US3 table migration (documented pattern in CLAUDE.md "Column Name Drift" lesson learned).

**Action required before refactoring**: Verify column existence in the live `perseus_dev` database (may differ from file-based DDL), or escalate to DBA to confirm whether `merged_into`, `source_process_id`, and `goo_id` need to be added to the deployed tables.

### P2 Issues — Fix Before STAGING Deployment

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P2-1 | `UNION` (not `UNION ALL`) — deduplication is intentional but adds full sort cost | All three UNION branches | Sorting/hashing the union result set on each query. If the three branches produce disjoint rows (likely), UNION ALL + DISTINCT would perform better. Validate business requirement for deduplication. |
| P2-2 | No `CREATE OR REPLACE` idempotency in original T-SQL | `CREATE VIEW goo_relationship` | Deployment script must use `CREATE OR REPLACE VIEW` for safe re-runs |
| P2-3 | Third UNION branch has no alias disambiguation — `i` and `o` aliases for two `goo` self-joins could be confused in maintenance | `JOIN goo i ON i.uid = r.feedstock_material` and `JOIN goo o ON o.uid = r.resultant_material` | Low correctness risk (PostgreSQL resolves correctly) but maintainability concern |

### P3 Issues — Track for Future Improvement

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| P3-1 | No `SECURITY INVOKER` declaration | View header | PostgreSQL defaults to SECURITY INVOKER, but should be explicit per constitution security principle |
| P3-2 | No comments or header documentation | Entire view | Does not conform to project maintainability standard |
| P3-3 | Column list `(parent, child)` not in T-SQL original header — SCT added it correctly | SCT output only | Good practice: add explicit column list to PostgreSQL DDL for clear interface contract |
| P3-4 | UNION deduplication strategy not validated against data patterns | All branches | If all three branches produce structurally different relationship types, UNION ALL + outer DISTINCT may be cleaner and expose the deduplication intent |

---

## T-SQL to PostgreSQL Transformations Required

| # | T-SQL Pattern | PostgreSQL Equivalent | Applied In | Notes |
|---|---------------|----------------------|------------|-------|
| 1 | `[dbo].` schema prefix | `perseus.` | All local table references | SCT used `perseus_dbo` — must correct to `perseus` |
| 2 | `[hermes].` schema prefix | `hermes.` | FDW table reference (`hermes.run`) | SCT used `perseus_hermes` — must correct to `hermes` |
| 3 | `ISNULL(r.feedstock_material, '') != ISNULL(r.resultant_material, '')` | `COALESCE(r.feedstock_material, '') != COALESCE(r.resultant_material, '')` | Third UNION WHERE clause | SCT applied COALESCE but added incorrect `::CITEXT` cast — remove CITEXT |
| 4 | `::CITEXT` cast on TEXT comparison | Remove — use plain `TEXT` comparison | Third UNION WHERE clause | CITEXT changes comparison to case-insensitive; original was case-sensitive. Not applicable here. |
| 5 | `CREATE VIEW` (no idempotency) | `CREATE OR REPLACE VIEW` | View header | Enables safe re-deployment |
| 6 | No column list in header | Add `(parent, child)` | View header | Makes column interface contract explicit |

**No additional T-SQL-specific function transforms required** — this view uses only JOIN, UNION, WHERE with IS NOT NULL and inequality comparisons.

---

## AWS SCT Assessment

### What SCT Got Right

- Converted `ISNULL(x, y)` to `COALESCE(x, y)` in the third UNION branch WHERE clause.
- Added explicit column list `(parent, child)` to the view header.
- Preserved the three-branch UNION structure and all join conditions.
- Applied `CREATE OR REPLACE VIEW` idiom.
- Raised HIGH severity alerts on unresolved column names — the warnings were correct; the columns are genuinely absent from the deployed table DDL.

### What SCT Got Wrong / Missed

- **Schema naming (systematic error)**: Used `perseus_dbo` for all local objects and `perseus_hermes` for FDW objects. Both are wrong — correct schemas are `perseus` and `hermes` respectively.
- **CITEXT cast (logic error)**: Applied `::CITEXT` to the COALESCE result in the WHERE clause. This changes the comparison from case-sensitive (`TEXT != TEXT`) to case-insensitive (`CITEXT != CITEXT`). The original T-SQL `ISNULL` comparison is byte-by-byte (case-sensitive). This is a silent behavioral change.
- **Column resolution errors**: SCT correctly identified that `merged_into`, `goo_id`, and `source_process_id` cannot be resolved — but it did not investigate further. The appropriate action for unresolved columns is to flag for human review, not to embed comment-markers inline that corrupt the SQL syntax (the inline comments make the SCT output non-parseable without manual cleanup).
- **No FDW blocking guidance**: SCT did not annotate the third branch as requiring a separate FDW configuration step.

### SCT Reliability Score: 4/10

The CITEXT logic error directly changes query semantics and would produce incorrect results in production. The schema errors and the column-resolution failures (while flagged) make the SCT output non-deployable without substantial manual rework. The structural preservation of the three-branch UNION is the only reliable contribution.

---

## FDW Dependency Analysis

### Deployment Blocker

The third UNION branch (`SELECT i.id, o.id FROM hermes.run r JOIN goo i ... JOIN goo o ...`) references `hermes.run`, which is a foreign table defined via `postgres_fdw`. The FDW server (`hermes_server`) is not yet configured — `CREATE SERVER` and `CREATE USER MAPPING` statements in `hermes_fdw_setup.sql` are commented out pending credentials.

**Without the FDW server live, the entire view (all three branches combined) will fail to create** because PostgreSQL validates all object references at `CREATE VIEW` time, including foreign table schemas.

### Partial Deployment Strategy (Without FDW)

A two-branch interim view (`goo_relationship_v1`) can be deployed immediately using only the first two UNION branches, which have no FDW dependency. This interim view:

- Captures merge relationships (`goo.merged_into IS NOT NULL`)
- Captures process-ancestry relationships (`fatsmurf.goo_id + goo.source_process_id` join chain)
- Excludes hermes fermentation run relationships

**Prerequisite**: Resolve P1-2 first — confirm `merged_into`, `source_process_id` (on `goo`), and `goo_id` (on `fatsmurf`) exist in the live database before deploying even the partial view.

### What Can Be Tested Without FDW

- Branch 1 (merge relationships): Verify `SELECT id AS parent, merged_into AS child FROM perseus.goo WHERE merged_into IS NOT NULL` returns expected rows.
- Branch 2 (process ancestry): Verify `SELECT p.id, c.id FROM perseus.goo p JOIN perseus.fatsmurf fs ON fs.goo_id = p.id JOIN perseus.goo c ON c.source_process_id = fs.id` returns expected rows.
- UNION deduplication: Confirm no duplicate `(parent, child)` pairs in the two-branch result.
- `vw_jeremy_runs` cannot be tested until full three-branch `goo_relationship` is deployed with FDW live.

---

## Dependencies Verified

| Object | Type | Schema | Status | Notes |
|--------|------|--------|--------|-------|
| `goo` | Base table | `perseus` | Deployed (DDL file present) | `merged_into` and `source_process_id` columns ABSENT from DDL — P1 blocker |
| `fatsmurf` | Base table | `perseus` | Deployed (DDL file present) | `goo_id` column ABSENT from DDL — P1 blocker |
| `hermes.run` | Foreign table | `hermes` | DDL defined; FDW server not configured | 90-column FOREIGN TABLE; `feedstock_material VARCHAR(50)`, `resultant_material TEXT` confirmed |
| `vw_jeremy_runs` | Dependent view | `perseus` | Not yet deployed | Blocked by this view (goo_relationship) + hermes FDW |

### Column Drift Action Required

Before any deployment of `goo_relationship`, the following must be resolved:

```sql
-- Verify in live perseus_dev database:
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'perseus'
  AND table_name IN ('goo', 'fatsmurf')
  AND column_name IN ('merged_into', 'source_process_id', 'goo_id')
ORDER BY table_name, column_name;
```

If the columns exist in the live database but are absent from the DDL files, update the DDL files to match the deployed schema. If the columns are genuinely absent, they must be added via ALTER TABLE before this view can be created.

---

## Proposed PostgreSQL DDL

### Version 1 (v1) — Two Branches Only (No FDW, Deployable Now)

**Prerequisite**: `merged_into`, `source_process_id` on `perseus.goo`, and `goo_id` on `perseus.fatsmurf` must be confirmed present in the live database.

**Dialect**: PostgreSQL 17
**Schema**: `perseus`
**File**: `source/building/pgsql/refactored/15.create-view/goo_relationship.sql` (interim v1)

```sql
-- =============================================================================
-- View: perseus.goo_relationship  [VERSION 1 — partial, no FDW]
-- Source: SQL Server [dbo].[goo_relationship]
-- Type: Standard View (2-branch UNION — third branch omitted until hermes FDW live)
-- Priority: P1 (High)
-- Wave: Wave 0 (depends only on local base tables in this version)
-- Depends on: perseus.goo, perseus.fatsmurf
-- Blocks: perseus.vw_jeremy_runs (cannot deploy until v2 with third branch)
-- FDW dependency: hermes.run (third branch — EXCLUDED in this version)
-- Description: Returns parent-child relationships between goo (material) records.
--   Branch 1: Merge relationships (goo records merged into another).
--   Branch 2: Process-ancestry relationships via fatsmurf run records.
--   Branch 3 (EXCLUDED): Hermes fermentation feedstock-to-resultant relationships.
-- Author: migration US1-critical-views / T037
-- Date: 2026-02-19
-- IMPORTANT: Replace with v2 when hermes FDW server is live.
-- =============================================================================

-- PREREQUISITE CHECK — run before deploying:
-- SELECT column_name FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'goo'
--   AND column_name IN ('merged_into', 'source_process_id');
-- SELECT column_name FROM information_schema.columns
-- WHERE table_schema = 'perseus' AND table_name = 'fatsmurf'
--   AND column_name = 'goo_id';

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
-- p = parent goo (produced the fatsmurf run)
-- fs = the fatsmurf run record linking parent to child
-- c = child goo (created from the fatsmurf run)
SELECT
    p.id AS parent,
    c.id AS child
FROM perseus.goo      AS p
JOIN perseus.fatsmurf AS fs ON fs.goo_id          = p.id
JOIN perseus.goo      AS c  ON c.source_process_id = fs.id;

COMMENT ON VIEW perseus.goo_relationship IS
    'Parent-child relationships between goo (material) records. '
    'VERSION 1 (partial): includes merge relationships (Branch 1) and '
    'process-ancestry via fatsmurf (Branch 2). '
    'Branch 3 (hermes fermentation feedstock/resultant) excluded pending hermes FDW. '
    'Replace with full v2 when hermes_server is configured. '
    'P1 - Wave 0. Blocks: vw_jeremy_runs.';
```

---

### Version 2 (v2) — Full Three Branches (With FDW Active)

**Prerequisite**: All three columns confirmed present AND `hermes_server` FDW connection live.

**Dialect**: PostgreSQL 17
**Schema**: `perseus` (local tables), `hermes` (FDW table)
**File**: `source/building/pgsql/refactored/15.create-view/goo_relationship.sql` (replace v1 with this)

```sql
-- =============================================================================
-- View: perseus.goo_relationship  [VERSION 2 — full, with FDW]
-- Source: SQL Server [dbo].[goo_relationship]
-- Type: Standard View (3-branch UNION)
-- Priority: P1 (High)
-- Wave: Wave 0 (depends on local base tables + hermes FDW)
-- Depends on: perseus.goo, perseus.fatsmurf, hermes.run (FDW)
-- Blocks: perseus.vw_jeremy_runs (P3)
-- FDW dependency: hermes.run via hermes_server (postgres_fdw)
-- Description: Returns parent-child relationships between goo (material) records.
--   Branch 1: Merge relationships (goo records merged into another).
--   Branch 2: Process-ancestry relationships via fatsmurf run records.
--   Branch 3: Hermes fermentation feedstock-to-resultant material relationships.
-- Author: migration US1-critical-views / T037
-- Date: 2026-02-19
-- =============================================================================

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
SELECT
    p.id AS parent,
    c.id AS child
FROM perseus.goo      AS p
JOIN perseus.fatsmurf AS fs ON fs.goo_id          = p.id
JOIN perseus.goo      AS c  ON c.source_process_id = fs.id

UNION

-- Branch 3: Hermes fermentation run relationships (FDW).
-- A hermes.run record links a feedstock material (input) to a resultant material
-- (output) via their UID strings stored in the run table.
-- i = goo record for the feedstock (input) material
-- o = goo record for the resultant (output) material
-- The WHERE clause excludes runs where feedstock and resultant are the same
-- (same-material runs have no meaningful parent-child relationship).
SELECT
    i.id AS parent,
    o.id AS child
FROM hermes.run AS r
JOIN perseus.goo AS i ON i.uid = r.feedstock_material
JOIN perseus.goo AS o ON o.uid = r.resultant_material
WHERE COALESCE(r.feedstock_material, '') != COALESCE(r.resultant_material, '');

COMMENT ON VIEW perseus.goo_relationship IS
    'Parent-child relationships between goo (material) records. '
    'Branch 1: merge relationships (merged_into IS NOT NULL). '
    'Branch 2: process-ancestry via fatsmurf runs (goo.source_process_id). '
    'Branch 3: hermes fermentation feedstock/resultant pairs (hermes.run FDW). '
    'UNION deduplicates across all three relationship types. '
    'P1 - Wave 0. Blocks: vw_jeremy_runs.';
```

### Key DDL Decisions

| Decision | Rationale |
|----------|-----------|
| Schema `perseus` on local tables | Corrects SCT `perseus_dbo` error; schema-qualifies per constitution principle 7 |
| Schema `hermes` on FDW table | Corrects SCT `perseus_hermes` error; matches deployed `hermes.run` foreign table definition |
| Removed `::CITEXT` cast | Original T-SQL comparison is case-sensitive; CITEXT changes semantics silently. Plain `TEXT != TEXT` is correct. |
| `COALESCE(x, '') != COALESCE(y, '')` not `COALESCE(x, '') != ''` | Corrects the T-SQL semantic: the original checks feedstock != resultant (not feedstock != empty). SCT preserved this correctly (minus the CITEXT error). |
| `UNION` (not `UNION ALL`) | Preserves original deduplication semantics across relationship types |
| Explicit table aliases in all branches | Removes ambiguity in multi-join branches; improves maintainability |
| `CREATE OR REPLACE VIEW` | Idempotent deployment; enables safe re-runs for v1 -> v2 upgrade |
| Column list `(parent, child)` in view header | Explicit interface contract; matches SCT output practice |
| `COMMENT ON VIEW` | Documents purpose, priority, wave, and FDW status per maintainability standard |
| Two-version strategy (v1/v2) | Unblocks 19 views that can proceed without FDW while hermes connection is being configured |

---

## Quality Score Estimate

This score reflects the **proposed v2 PostgreSQL DDL** above (post-correction).

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9/10 | Valid PostgreSQL 17 syntax; schema-qualified references; COALESCE without CITEXT. Conditional on column existence confirmation (P1-2). |
| Logic Preservation | 8/10 | All three branches semantically identical to T-SQL original. CITEXT removal restores correct case-sensitive comparison. -1 for unresolved column drift risk (P1-2) pending database verification. |
| Performance | 7/10 | UNION deduplification adds sort/hash cost across three branches. Branch 2 double-join on `goo` via `fatsmurf` may benefit from indexes on `fatsmurf.goo_id` and `goo.source_process_id`. FDW branch performance is externally controlled by hermes server. |
| Maintainability | 9/10 | Header documentation, branch comments, COMMENT ON VIEW. Column list in header. snake_case, schema-qualified. v1/v2 strategy documented. |
| Security | 8/10 | Defaults to SECURITY INVOKER (correct). Schema-qualified references. No dynamic SQL. -1 for not declaring SECURITY INVOKER explicitly. |
| **Overall** | **8.2/10** | Exceeds 7.0/10 minimum. Blocked from final score until P1-2 column drift is resolved. |

---

## Refactoring Effort Estimate

- **Effort**: 2.5 hours
  - 0.5h: Verify column existence in live `perseus_dev` database for `merged_into`, `source_process_id`, `goo_id` (P1-2 resolution)
  - 0.5h: Apply schema renames (`perseus_dbo` -> `perseus`, `perseus_hermes` -> `hermes`), remove CITEXT casts, add COALESCE correctly
  - 0.5h: Write v1 DDL (two-branch), validate syntax with `psql -d perseus_dev`
  - 0.5h: Write v2 DDL (three-branch), validate syntax (requires FDW or mock schema)
  - 0.5h: Add documentation header, COMMENT ON VIEW, review consistency with hermes_run analysis
- **Risk**: Medium-High
  - High: Column drift (P1-2) is a genuine blocker — if `merged_into`, `source_process_id`, and `goo_id` are absent from the live database, the entire view (even v1) cannot be created without schema changes.
  - Medium: FDW schema naming (`hermes` vs `perseus_hermes`) must be confirmed against the live server configuration once FDW is active.
  - Low: The view structure and transformation logic are straightforward once column existence is confirmed.
- **Testing gate**: After refactoring, validate:
  1. v1 creates without error (Branches 1 + 2 only)
  2. Row count in Branch 1 matches `SELECT COUNT(*) FROM perseus.goo WHERE merged_into IS NOT NULL`
  3. No duplicate `(parent, child)` pairs in result
  4. v2 creates without error when FDW is live
  5. Branch 3 returns rows only where feedstock_material != resultant_material
  6. `vw_jeremy_runs` can be created after v2 is deployed

---

*Generated by T037 | Branch: us1-critical-views | 2026-02-19*
