# Analysis: vw_process_upstream (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_process_upstream` |
| PostgreSQL name | `perseus.vw_process_upstream` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 5/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.material_transition`, `perseus.transition_material`, `perseus.fatsmurf` (all base tables, deployed ✅) |
| Blocks | `perseus.vw_fermentation_upstream` (Wave 1 recursive CTE) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/17.perseus.dbo.vw_process_upstream.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/17.perseus.vw_process_upstream.sql` |

---

## Source Query Analysis

The view joins `material_transition` to `transition_material` on `material_id`, then joins `fatsmurf` twice (aliased `fs` and `fs2`) to resolve the process type of each end of the transition. The key business logic is:

- `mt.transition_id` = the **destination** process (upstream end)
- `tm.transition_id` = the **source** process (downstream end, where the journey begins)
- `fs.smurf_id` = the `smurf_id` (process type integer) of the **destination** process
- `fs2.smurf_id` = the `smurf_id` (process type integer) of the **source** process
- `mt.material_id` = the material that connects the two processes

The join path encodes the upstream relationship: `transition_material.material_id = material_transition.material_id` means the same material appears as both a source material (in `material_transition`) and a destination material (in `transition_material`), connecting two process steps.

`fatsmurf.uid` is a TEXT column used as the join key to both `material_transition.transition_id` (TEXT) and `transition_material.transition_id` (TEXT).

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_process_upstream` with all table references under `perseus_dbo`. The production schema is `perseus`. Deployment against a `perseus_dbo`-namespaced schema will fail because base tables are deployed under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — `WITH SCHEMABINDING` clause must be removed

**Severity:** P2
**Location:** T-SQL original — `CREATE VIEW [dbo].[vw_process_upstream] WITH SCHEMABINDING AS`
**Description:** `WITH SCHEMABINDING` is a SQL Server-only clause that binds a view to the schema of its underlying objects, preventing schema changes to those objects while the view exists. PostgreSQL has no equivalent and will reject the clause with a syntax error.
**Fix:** Remove `WITH SCHEMABINDING` from the CREATE VIEW statement. AWS SCT correctly strips this clause.

---

#### P2-02 — `LEFT OUTER JOIN` verbosity — minor style issue

**Severity:** P2 (low — functionally correct)
**Location:** No occurrence in `vw_process_upstream` specifically — this view uses INNER JOINs throughout
**Description:** The T-SQL uses implicit `JOIN` (inner join). AWS SCT correctly preserves inner join semantics. No outer joins present in this view — no action needed. Noted for completeness.

---

#### P2-03 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output. Constitution Article VI requires all production objects to be documented.
**Fix:** Add `COMMENT ON VIEW perseus.vw_process_upstream IS '...'`.

---

### P3 Issues

#### P3-01 — Bracket notation `[dbo].[vw_process_upstream]` in T-SQL

**Severity:** P3 (informational — handled by AWS SCT)
**Location:** T-SQL original
**Description:** The T-SQL uses SQL Server bracket notation `[dbo].[vw_process_upstream]`. AWS SCT correctly strips the brackets. No action required beyond confirming the SCT output.

---

#### P3-02 — Missing `OR REPLACE` in T-SQL original (not an issue in production DDL)

**Severity:** P3
**Location:** DDL header
**Description:** AWS SCT correctly emits `CREATE OR REPLACE VIEW`. Ensure the production DDL retains this for idempotent re-deployment.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `WITH SCHEMABINDING` | Remove clause | CREATE VIEW header | Not supported in PostgreSQL |
| `[dbo].[vw_process_upstream]` | `perseus.vw_process_upstream` | CREATE VIEW header | Drop brackets, correct schema |
| `dbo.material_transition` | `perseus.material_transition` | FROM clause | Schema correction |
| `dbo.transition_material` | `perseus.transition_material` | JOIN clause | Schema correction |
| `dbo.fatsmurf` (×2, aliases `fs`, `fs2`) | `perseus.fatsmurf` | JOIN clauses | Schema correction |
| `JOIN dbo.fatsmurf fs on mt.transition_id = fs.uid` | Use `ON` (lowercase, formatted) | JOIN clauses | Style only — semantics preserved |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_process_upstream IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`17.perseus.vw_process_upstream.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_process_upstream (source_process, destination_process, source_process_type, destination_process_type, connecting_material) AS
SELECT
    tm.transition_id AS source_process, mt.transition_id AS destination_process, fs.smurf_id AS source_process_type, fs2.smurf_id AS destination_process_type, mt.material_id AS connecting_material
    FROM perseus_dbo.material_transition AS mt
    JOIN perseus_dbo.transition_material AS tm
        ON tm.material_id = mt.material_id
    JOIN perseus_dbo.fatsmurf AS fs
        ON mt.transition_id = fs.uid
    JOIN perseus_dbo.fatsmurf AS fs2
        ON tm.transition_id = fs2.uid;
```

**What SCT got right:**
- Removed `WITH SCHEMABINDING` — correct.
- Added `CREATE OR REPLACE` — idempotent deployment.
- Added column alias list in header — good documentation practice.
- Removed bracket notation `[dbo].[...]` — correct.
- Added explicit `AS` keywords for table aliases — style improvement.
- Preserved all join logic faithfully.
- No T-SQL-specific syntax in the body to convert (no CONVERT, ISNULL, GETDATE, string concat).

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect, will fail at deployment.
2. No `COMMENT ON VIEW` statement.
3. Minor formatting: single-line SELECT column list (readability concern, not a functional issue).

**SCT reliability score: 7/10**
Logic is correct; schema name is the only material defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_process_upstream
-- Description: Exposes process-to-process upstream relationships derived from
--              material lineage. Joins material_transition and transition_material
--              on the shared material_id to identify pairs of process steps
--              connected by a common material. Joins fatsmurf twice (once for each
--              process) to resolve process type identifiers (smurf_id).
--
--              source_process:       smurf uid of the downstream (origin) process
--              destination_process:  smurf uid of the upstream (target) process
--              source_process_type:  smurf_id (integer) of the destination process
--              destination_process_type: smurf_id (integer) of the source process
--              connecting_material:  material_id (TEXT) linking the two processes
--
--              NOTE: 'source_process_type' derives from the destination fatsmurf (fs)
--              and 'destination_process_type' from the source fatsmurf (fs2).
--              This naming reflects the T-SQL original and must be preserved for
--              backward compatibility with dependent objects.
--
-- Depends on:  perseus.material_transition (base table ✅)
--              perseus.transition_material (base table ✅)
--              perseus.fatsmurf (base table ✅)
-- Blocks:      perseus.vw_fermentation_upstream (Wave 1)
-- Wave:        Wave 0
-- T-SQL ref:   dbo.vw_process_upstream
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_process_upstream (
    source_process,
    destination_process,
    source_process_type,
    destination_process_type,
    connecting_material
) AS
SELECT
    tm.transition_id   AS source_process,
    mt.transition_id   AS destination_process,
    fs.smurf_id        AS source_process_type,
    fs2.smurf_id       AS destination_process_type,
    mt.material_id     AS connecting_material
FROM perseus.material_transition AS mt
JOIN perseus.transition_material AS tm
    ON tm.material_id = mt.material_id
JOIN perseus.fatsmurf AS fs
    ON mt.transition_id = fs.uid
JOIN perseus.fatsmurf AS fs2
    ON tm.transition_id = fs2.uid;

-- Documentation
COMMENT ON VIEW perseus.vw_process_upstream IS
    'Process-to-process upstream relationships derived from material lineage. '
    'For each material that connects two process steps, exposes the source process, '
    'destination process, their respective smurf_id type codes, and the connecting '
    'material uid. Used by vw_fermentation_upstream (Wave 1 recursive CTE) to '
    'traverse fermentation process chains (process type = 22). '
    'Depends on: material_transition, transition_material, fatsmurf (all base tables). '
    'T-SQL source: dbo.vw_process_upstream | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Valid PostgreSQL 17 syntax. Standard INNER JOINs throughout. |
| Logic Preservation | 9.5/10 | Business logic faithfully preserved. Column naming preserved for backward compatibility. Minor deduction: the semantic inversion in column naming (source_process_type derives from destination fatsmurf) is a design quirk carried from T-SQL — preserved deliberately. |
| Performance | 8/10 | Four-table join. Index coverage depends on: `fatsmurf.uid` (TEXT, used in two join conditions) should have an index; `material_transition.material_id` and `transition_material.material_id` join condition should be covered. Verify index existence post-deployment with EXPLAIN ANALYZE. |
| Maintainability | 9/10 | Clear column aliases in header, COMMENT ON VIEW present, schema-qualified, formatted. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.2/10** | Exceeds PROD target (8.0). Simple conversion with only schema correction required. |

---

## Index Recommendations

Before deploying, verify the following indexes exist (check with `\d perseus.fatsmurf`, `\d perseus.material_transition`):

| Table | Column(s) | Type | Purpose |
|-------|-----------|------|---------|
| `perseus.fatsmurf` | `uid` | Should be PRIMARY KEY or UNIQUE | Join condition `fs.uid = mt.transition_id` and `fs2.uid = tm.transition_id` |
| `perseus.material_transition` | `material_id` | Index | Join condition `tm.material_id = mt.material_id` |
| `perseus.transition_material` | `material_id` | Index | Join condition `tm.material_id = mt.material_id` |

If `fatsmurf.uid` is not indexed, the two double-join lookups will be sequential scans on every query execution, which becomes expensive as the fatsmurf table grows.

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.5 hours |
| Risk | Low |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.15 h — Schema correction (`perseus_dbo` → `perseus`)
- 0.15 h — Format DDL, add column alias list, add `COMMENT ON VIEW`
- 0.1 h — Verify index coverage with `\d` on DEV
- 0.1 h — Syntax validation with `psql` on DEV, record quality score

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
