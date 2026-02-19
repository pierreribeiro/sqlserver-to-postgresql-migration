# Analysis: vw_material_transition_material_up (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_material_transition_material_up` |
| PostgreSQL name | `perseus.vw_material_transition_material_up` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 3/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.transition_material`, `perseus.material_transition` (base tables, deployed ✅) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/16.perseus.dbo.vw_material_transition_material_up.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/16.perseus.vw_material_transition_material_up.sql` |

---

## Source Query Analysis

The view drives from `transition_material` (all transition-to-material edges) and LEFT OUTER JOINs `material_transition` on `transition_id`. This means:

- Every row from `transition_material` appears, whether or not a matching `material_transition` row exists.
- `source_uid` (`mt.material_id`) will be NULL when there is no upstream `material_transition` matching the `transition_id`.
- `destination_uid` (`tm.material_id`) is always populated (from `transition_material`).
- `transition_uid` (`tm.transition_id`) is always populated.

This LEFT JOIN pattern exposes all material destinations (from `transition_material`) with their optional upstream source material (from `material_transition`). It is the "upstream by material" complement to `vw_process_upstream` (which operates at the process/fatsmurf level).

The T-SQL original also contains a commented-out `DROP VIEW` statement (`-- DROP VIEW [dbo].[vw_material_transition_material_up]`) which the AWS SCT preserved as a comment (`/* DROP VIEW [...] */`). This comment should be removed from production DDL as it serves no purpose in a CREATE script and may cause confusion.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_material_transition_material_up` with all table references under `perseus_dbo`. The production schema is `perseus`. All base tables are deployed under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — `WITH SCHEMABINDING` clause must be removed

**Severity:** P2
**Location:** T-SQL original — `CREATE VIEW [dbo].[vw_material_transition_material_up] WITH SCHEMABINDING AS`
**Description:** SQL Server-only clause — not supported in PostgreSQL. AWS SCT correctly strips this.
**Fix:** Remove `WITH SCHEMABINDING`. AWS SCT handles this.

---

#### P2-02 — Orphan comment `/* DROP VIEW [...] */` in AWS SCT output

**Severity:** P2
**Location:** AWS SCT output — line 2: `/* DROP VIEW [dbo].[vw_material_transition_material_up] */`
**Description:** The T-SQL original contains a commented-out DROP statement. AWS SCT faithfully converts it to a block comment. This comment has no function in a CREATE script, references a T-SQL bracket syntax object name, and should not appear in production PostgreSQL DDL.
**Fix:** Remove this comment from the production DDL.

---

#### P2-03 — `LEFT OUTER JOIN` → `LEFT JOIN` (style)

**Severity:** P2 (style only — functionally equivalent)
**Location:** FROM clause
**Description:** `LEFT OUTER JOIN` is valid ANSI SQL but the `OUTER` keyword is redundant. PostgreSQL accepts both. The project constitution prefers ANSI-standard concise forms.
**Fix:** Use `LEFT JOIN` (drop `OUTER`). AWS SCT preserves `LEFT OUTER JOIN` — normalize in production DDL.

---

#### P2-04 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_material_transition_material_up IS '...'`.

---

### P3 Issues

#### P3-01 — Bracket notation and DROP comment in T-SQL original

**Severity:** P3 (informational — handled by SCT or removed)
**Location:** T-SQL original
**Description:** `[dbo].[vw_material_transition_material_up]` brackets and the commented DROP statement are T-SQL artifacts. AWS SCT removes brackets and converts the DROP comment; production DDL should remove the comment entirely.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `WITH SCHEMABINDING` | Remove clause | CREATE VIEW header | Not supported in PostgreSQL |
| `[dbo].[vw_material_transition_material_up]` | `perseus.vw_material_transition_material_up` | CREATE VIEW header | Drop brackets, correct schema |
| `-- DROP VIEW [dbo].[vw_material_transition_material_up]` | Remove entirely | Pre-CREATE comment | No purpose in production DDL |
| `dbo.transition_material` | `perseus.transition_material` | FROM clause | Schema correction |
| `dbo.material_transition` | `perseus.material_transition` | JOIN clause | Schema correction |
| `LEFT OUTER JOIN` | `LEFT JOIN` | JOIN clause | Drop redundant OUTER keyword |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_material_transition_material_up IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`16.perseus.vw_material_transition_material_up.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_material_transition_material_up (source_uid, destination_uid, transition_uid) AS
/* DROP VIEW [dbo].[vw_material_transition_material_up] */
SELECT
    mt.material_id AS source_uid, tm.material_id AS destination_uid, tm.transition_id AS transition_uid
    FROM perseus_dbo.transition_material AS tm
    LEFT OUTER JOIN perseus_dbo.material_transition AS mt
        ON tm.transition_id = mt.transition_id;
```

**What SCT got right:**
- Removed `WITH SCHEMABINDING` — correct.
- Added `CREATE OR REPLACE` — idempotent.
- Added column alias list `(source_uid, destination_uid, transition_uid)` in header — correct.
- Removed bracket notation — correct.
- Preserved LEFT OUTER JOIN semantics faithfully.
- No T-SQL-specific syntax in body (no CONVERT, ISNULL, GETDATE, string concat).

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. Preserved the orphan DROP comment from T-SQL — should be removed.
3. No `COMMENT ON VIEW` statement.
4. `LEFT OUTER JOIN` retained — minor style issue.

**SCT reliability score: 7/10**
Logic is fully correct. Schema name and orphan comment are the only defects.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_material_transition_material_up
-- Description: Upstream material-to-material link view. Drives from transition_material
--              (all known transition→material destination edges) and LEFT JOINs
--              material_transition to expose the optional upstream source material.
--
--              source_uid:      material_id from material_transition (NULL if no upstream)
--              destination_uid: material_id from transition_material (always populated)
--              transition_uid:  transition_id linking the two materials
--
--              Rows where source_uid IS NULL indicate materials that are the "start"
--              of a lineage chain (no upstream material feeds into their transition).
--
-- Depends on:  perseus.transition_material (base table ✅)
--              perseus.material_transition (base table ✅)
-- Blocks:      None
-- Wave:        Wave 0
-- T-SQL ref:   dbo.vw_material_transition_material_up
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_material_transition_material_up (
    source_uid,
    destination_uid,
    transition_uid
) AS
SELECT
    mt.material_id     AS source_uid,
    tm.material_id     AS destination_uid,
    tm.transition_id   AS transition_uid
FROM perseus.transition_material AS tm
LEFT JOIN perseus.material_transition AS mt
    ON tm.transition_id = mt.transition_id;

-- Documentation
COMMENT ON VIEW perseus.vw_material_transition_material_up IS
    'Upstream material link view. Enumerates all transition_material edges with '
    'their optional upstream source material from material_transition. '
    'source_uid is NULL when no material_transition exists for that transition_id '
    '(indicating a lineage chain starting point). '
    'Depends on: transition_material, material_transition (base tables). '
    'T-SQL source: dbo.vw_material_transition_material_up | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Two-table LEFT JOIN — minimal syntax risk. |
| Logic Preservation | 10/10 | LEFT JOIN semantics preserved. NULL source_uid behavior is intentional and documented. |
| Performance | 8.5/10 | Index coverage on `material_transition.transition_id` and `transition_material.transition_id` is key. Both columns are likely PKs or FK targets — verify post-deployment. |
| Maintainability | 9/10 | Clear aliases, COMMENT ON VIEW present, orphan comment removed, schema-qualified. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.4/10** | Exceeds PROD target (8.0). Very simple conversion. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.1 h — Schema correction, remove orphan comment, change `LEFT OUTER JOIN` to `LEFT JOIN`
- 0.1 h — Add `COMMENT ON VIEW`, format DDL with column alias list
- 0.05 h — Syntax validation with `psql` on DEV

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
