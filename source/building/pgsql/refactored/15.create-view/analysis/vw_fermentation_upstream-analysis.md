# Analysis: vw_fermentation_upstream (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_fermentation_upstream` |
| PostgreSQL name | `perseus.vw_fermentation_upstream` |
| Type | Recursive CTE View |
| Priority | P2 |
| Complexity | 6/10 |
| Wave | Wave 1 (depends on `vw_process_upstream`) |
| Depends on | `perseus.vw_process_upstream` (Wave 0 view — must be deployed first) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/11.perseus.dbo.vw_fermentation_upstream.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/11.perseus.vw_fermentation_upstream.sql` |

---

## Source Query Analysis

This recursive CTE view traverses process-to-process upstream relationships, filtering specifically for fermentation process type (smurf_id = 22). It uses `vw_process_upstream` as its data source (not the base tables directly).

**CTE structure:**

**Anchor term:**
```sql
SELECT pt.destination_process AS start_point,
       pt.destination_process AS parent,
       pt.destination_process_type AS process_type,
       pt.source_process AS child,
       CAST('/' + pt.destination_process AS VARCHAR(255)) AS path,
       1 AS level
FROM vw_process_upstream pt
WHERE source_process_type = 22
```
Seeds one row per fermentation-typed source process. `destination_process` is the start of the traversal chain. `source_process_type = 22` filters to rows where the source/origin process is of fermentation type (smurf_id 22). The path starts with `'/' + destination_process`.

**Recursive term:**
```sql
SELECT r.start_point, pt.destination_process, pt.destination_process_type AS process_type,
       pt.source_process,
       CASE WHEN pt.destination_process_type = 22
            THEN CAST(r.path + '/' + pt.source_process AS VARCHAR(255))
            ELSE r.path END,
       CASE WHEN pt.destination_process_type = 22 THEN r.level + 1 ELSE r.level END
FROM vw_process_upstream pt
JOIN upstream r ON pt.destination_process = r.child
WHERE pt.destination_process != pt.source_process
```
Walks one hop further upstream by joining `vw_process_upstream` on `destination_process = r.child`. Only extends the path/level counters when the destination is also a fermentation process (type 22). This means non-fermentation process types are traversed but don't contribute to path depth.

**Final SELECT:**
```sql
SELECT start_point, child AS end_point, path, level
FROM upstream WHERE process_type = 22
```
Filters the result to only fermentation-type processes (`process_type = 22`).

**Business logic interpretation:**
The view finds all upstream fermentation process chains. It starts from fermentation processes that have fermentation sources (anchor), traverses upstream through all process types (recursive step), but reports only the fermentation-to-fermentation hops. Non-fermentation intermediate processes are traversed but excluded from the final result.

**Key technical observations:**
- `destination_process`, `source_process` are TEXT columns (UIDs from fatsmurf) — string comparison in the path construction.
- The `CAST('/' + pt.destination_process AS VARCHAR(255))` pattern requires `WITH RECURSIVE` and `||` operator in PostgreSQL.
- The `WHERE pt.destination_process != pt.source_process` guard prevents self-loops (same as in the `upstream` view) but does NOT prevent multi-hop cycles (same cycle risk as documented in `upstream-analysis.md`).
- The internal CTE is named `upstream` — same as the existing `upstream` view. This is valid because the CTE name is scoped to this view's body; it does not reference the `perseus.upstream` view.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and `vw_process_upstream` reference
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_fermentation_upstream` with `FROM perseus_dbo.vw_process_upstream`. The view depends on `perseus.vw_process_upstream` (Wave 0).
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

#### P1-02 — `WITH RECURSIVE` required in PostgreSQL — not inferred automatically

**Severity:** P1
**Location:** CTE declaration in T-SQL — `WITH upstream AS (...)`
**Description:** T-SQL infers recursive CTE status automatically. PostgreSQL requires the explicit `WITH RECURSIVE` keyword. Without it, PostgreSQL will fail with `ERROR: recursive reference to query "upstream" must not appear within a subquery`. AWS SCT correctly adds `WITH RECURSIVE`.
**Fix:** AWS SCT handles this. Verify the production DDL retains `WITH RECURSIVE`.

---

#### P1-03 — `+` string concatenation → `||` operator

**Severity:** P1
**Location:** Anchor: `'/' + pt.destination_process` and Recursive: `r.path + '/' + pt.source_process`
**Description:** T-SQL uses `+` for string concatenation on TEXT/VARCHAR columns. PostgreSQL uses `||`. If the `+` operator is used in PostgreSQL with VARCHAR/TEXT operands it will fail with `ERROR: operator does not exist: text + text`. AWS SCT correctly converts these to `||`.
**Fix:** AWS SCT handles this. Verify production DDL uses `||`.

---

#### P1-04 — Cycle risk: `WHERE pt.destination_process != pt.source_process` is insufficient

**Severity:** P1
**Location:** Recursive term WHERE clause
**Description:** This guard prevents self-loops (a single process referencing itself) but does NOT prevent multi-hop cycles (A→B→A, A→B→C→A). If cycles exist in the `vw_process_upstream` data, the recursive CTE will exhaust the stack depth and raise `ERROR: stack depth limit exceeded`. The same cycle risk exists in `upstream-analysis.md` (P1-02 there). The CYCLE clause (PostgreSQL 14+) is the correct mitigation.
**Fix:** Add `CYCLE child SET is_cycle USING path_array` to the CTE. Filter `WHERE NOT is_cycle` in the outer SELECT.

---

### P2 Issues

#### P2-01 — Path width `VARCHAR(255)` should be `TEXT`

**Severity:** P2 (runtime failure risk on deep graphs)
**Location:** Anchor: `CAST('/' + pt.destination_process AS VARCHAR(255))`, Recursive: `CAST(r.path + '/' + pt.source_process AS VARCHAR(255))`
**Description:** PostgreSQL raises `ERROR: value too long for type character varying(255)` when the path string exceeds 255 characters. With process UIDs up to 50 characters each plus separators, paths longer than ~4-5 levels overflow. Unlike SQL Server (which silently truncates in some cases), PostgreSQL raises a hard error.
**Fix:** Use `TEXT` for the path accumulator — unbounded, idiomatic PostgreSQL. AWS SCT preserves the `VARCHAR(255)` cast — must be manually corrected.

---

#### P2-02 — CTE name `upstream` shadows the `perseus.upstream` view (naming concern)

**Severity:** P2 (clarity — not a functional issue)
**Location:** `WITH RECURSIVE upstream AS (...)`
**Description:** The internal CTE is named `upstream`, the same name as the `perseus.upstream` view. Within this view's body, references to `upstream` resolve to the CTE, not the view — which is correct. However, this naming choice is confusing for maintainers. Consider renaming the CTE to `fermentation_upstream` for clarity.
**Fix:** Rename internal CTE to `fermentation_chain` in the production DDL for clarity. This is a cosmetic improvement — no behavioral change.

---

#### P2-03 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_fermentation_upstream IS '...'`.

---

#### P2-04 — `<>` vs `!=` inequality operator

**Severity:** P2 (ANSI preference)
**Location:** Recursive term WHERE — `pt.destination_process != pt.source_process`
**Description:** `!=` is non-standard but supported in PostgreSQL. Constitution Article I (ANSI-SQL Primacy) prefers `<>`. Both are equivalent in PostgreSQL.
**Fix:** Use `<>` in production DDL.

---

### P3 Issues

#### P3-01 — Anchor path initialization uses `'/' || destination_process` — document semantics

**Severity:** P3 (clarity)
**Location:** Anchor — `'/'::TEXT || pt.destination_process AS path`
**Description:** The path starts with `'/' + destination_process` (the starting process UID). This means the path always has a leading slash and the start_point's UID as the first segment. The recursive step appends `'/' + source_process` each hop. Document this path format explicitly in comments.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW [dbo].[vw_fermentation_upstream] AS WITH upstream AS (...)` | `CREATE OR REPLACE VIEW perseus.vw_fermentation_upstream AS WITH RECURSIVE fermentation_chain AS (...)` | DDL header + CTE | `WITH RECURSIVE` required; rename CTE for clarity |
| `+` (string concat) | `\|\|` | Anchor and recursive path expressions | AWS SCT handles this |
| `CAST('/' + pt.destination_process AS VARCHAR(255))` | `('/' \|\| pt.destination_process)::TEXT` | Anchor term path | Change to TEXT — AWS SCT preserves VARCHAR(255) |
| `CAST(r.path + '/' + pt.source_process AS VARCHAR(255))` | `(r.path \|\| '/' \|\| pt.source_process)::TEXT` | Recursive term path | Change to TEXT — AWS SCT preserves VARCHAR(255) |
| Missing CYCLE clause | `CYCLE child SET is_cycle USING path_array` | After CTE body | PostgreSQL 14+ cycle detection |
| `FROM vw_process_upstream pt` | `FROM perseus.vw_process_upstream AS pt` | Both CTE terms | Explicit schema + AS alias |
| `!= ` | `<>` | Recursive WHERE clause | ANSI SQL preference |
| `[dbo].[vw_fermentation_upstream]` | `perseus.vw_fermentation_upstream` | DDL header | Schema correction |
| `perseus_dbo.vw_process_upstream` (SCT) | `perseus.vw_process_upstream` | Both CTE terms | Schema correction |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_fermentation_upstream IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`11.perseus.vw_fermentation_upstream.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_fermentation_upstream (start_point, end_point, path, level) AS
WITH RECURSIVE upstream
AS (SELECT
    pt.destination_process AS start_point, pt.destination_process AS parent, pt.destination_process_type AS process_type, pt.source_process AS child, CAST ('/' || pt.destination_process AS VARCHAR(255)) AS path, 1 AS level
    FROM perseus_dbo.vw_process_upstream AS pt
    WHERE source_process_type = 22
UNION ALL
SELECT
    r.start_point, pt.destination_process, pt.destination_process_type AS process_type, pt.source_process,
    CASE
        WHEN pt.destination_process_type = 22 THEN CAST (r.path || '/' || pt.source_process AS VARCHAR(255))
        ELSE r.path
    END,
    CASE
        WHEN pt.destination_process_type = 22 THEN r.level + 1
        ELSE r.level
    END
    FROM perseus_dbo.vw_process_upstream AS pt
    JOIN upstream AS r
        ON pt.destination_process = r.child
    WHERE pt.destination_process != pt.source_process)
SELECT
    start_point, child AS end_point, path, level
    FROM upstream
    WHERE process_type = 22;
```

**What SCT got right:**
- Added `WITH RECURSIVE` — correct and critical.
- Converted `+` to `||` — correct.
- Preserved all CTE structure (anchor, recursive, outer SELECT) — correct.
- Column alias list `(start_point, end_point, path, level)` in header — correct.
- `CAST` preserved (valid in PostgreSQL, though TEXT preferred over VARCHAR(255)).

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1-01.
2. `VARCHAR(255)` preserved for path accumulator — runtime failure risk on deep graphs (P2-01).
3. No CYCLE clause — cycle risk not addressed (P1-04).
4. No `COMMENT ON VIEW` — missing (P2-03).
5. CTE named `upstream` — potential confusion with `perseus.upstream` view (P2-02).

**SCT reliability score: 6/10**
The structural conversion (WITH RECURSIVE, || operator) is correct. The schema error, missing cycle protection, and VARCHAR(255) path width are material defects.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_fermentation_upstream
-- Description: Recursive CTE view that traverses upstream process chains,
--              filtering for fermentation process type (smurf_id = 22).
--              Seeds from vw_process_upstream where source_process_type = 22,
--              then walks upstream through all process types but counts depth
--              and builds path only for fermentation-type destination processes.
--              Final output: only rows where process_type = 22.
--
--              Path format: /<start_process_uid>/<hop1_uid>/<hop2_uid>/...
--
--              NOTE: Internal CTE renamed from 'upstream' to 'fermentation_chain'
--              to avoid naming confusion with the perseus.upstream view.
--
-- Depends on:  perseus.vw_process_upstream (Wave 0 view — must be deployed first)
-- Blocks:      None
-- Wave:        Wave 1
-- T-SQL ref:   dbo.vw_fermentation_upstream
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_fermentation_upstream (
    start_point,
    end_point,
    path,
    level
) AS
WITH RECURSIVE fermentation_chain AS (

    -- Anchor: fermentation processes that have fermentation-typed sources
    SELECT
        pt.destination_process                             AS start_point,
        pt.destination_process                             AS parent,
        pt.destination_process_type                        AS process_type,
        pt.source_process                                  AS child,
        ('/' || pt.destination_process)::TEXT              AS path,
        1                                                  AS level
    FROM perseus.vw_process_upstream AS pt
    WHERE pt.source_process_type = 22

    UNION ALL

    -- Recursive: walk one hop further upstream.
    -- Only extend path and level when the destination is fermentation type.
    SELECT
        r.start_point,
        pt.destination_process,
        pt.destination_process_type                        AS process_type,
        pt.source_process,
        CASE WHEN pt.destination_process_type = 22
             THEN (r.path || '/' || pt.source_process)::TEXT
             ELSE r.path
        END                                                AS path,
        CASE WHEN pt.destination_process_type = 22
             THEN r.level + 1
             ELSE r.level
        END                                                AS level
    FROM perseus.vw_process_upstream AS pt
    JOIN fermentation_chain AS r
        ON pt.destination_process = r.child
    WHERE pt.destination_process <> pt.source_process

)
-- Cycle detection (PostgreSQL 14+).
-- Tracks 'child' values per traversal path. Terminates recursion when a
-- previously-visited child is revisited. is_cycle = TRUE rows are suppressed.
CYCLE child SET is_cycle USING path_array

SELECT
    start_point,
    child   AS end_point,
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
    'Cycle-safe via PostgreSQL 14 CYCLE clause. '
    'Internal CTE renamed from ''upstream'' to ''fermentation_chain'' for clarity. '
    'Depends on: vw_process_upstream (Wave 0 view). '
    'T-SQL source: dbo.vw_fermentation_upstream | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9.5/10 | WITH RECURSIVE, UNION ALL, CYCLE clause — all valid PostgreSQL 17. Minor deduction for CYCLE clause being a newer feature (requires validation on deployed version). |
| Logic Preservation | 9/10 | CTE traversal logic preserved exactly. CTE renamed (cosmetic). CYCLE clause changes behavior only when cyclic data exists (improvement, not regression). `<>` vs `!=` — identical semantics. |
| Performance | 7/10 | Depends on `vw_process_upstream` being efficient (which in turn depends on the three-table join). Full graph expansion (no anchor filter) — all fermentation process chains evaluated on every query. Monitor with EXPLAIN ANALYZE. Index on `vw_process_upstream` columns used in the recursive join (`destination_process`) is critical. |
| Maintainability | 9/10 | Clear section comments, CTE renamed, COMMENT ON VIEW, `<>` inequality, TEXT path type. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **8.8/10** | Exceeds PROD target (8.0). |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 1.5 hours |
| Risk | Medium |
| Blocker | `perseus.vw_process_upstream` (Wave 0) must be deployed first |

**Effort breakdown:**
- 0.25 h — Schema correction, `||` verification, `<>` change
- 0.25 h — Change `VARCHAR(255)` to `TEXT` for path accumulator (both anchor and recursive)
- 0.5 h — Add CYCLE clause, test with synthetic data if cyclic process data possible
- 0.25 h — Rename CTE, add COMMENT ON VIEW, format DDL
- 0.25 h — Syntax validation with `psql` on DEV, EXPLAIN ANALYZE

**Risk: Medium** — CYCLE clause requires PostgreSQL 14+. Based on project spec (PostgreSQL 17+), this is confirmed supported. The CTE rename from `upstream` to `fermentation_chain` is non-breaking for this view but must be verified that no external code references the internal CTE name (it shouldn't — CTEs are view-scoped).

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
