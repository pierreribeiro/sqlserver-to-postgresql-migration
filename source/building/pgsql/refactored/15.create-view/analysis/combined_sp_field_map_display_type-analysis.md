# Analysis: combined_sp_field_map_display_type (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.combined_sp_field_map_display_type` |
| PostgreSQL name | `perseus.combined_sp_field_map_display_type` |
| Type | Standard View |
| Priority | P3 |
| Complexity | 5/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.smurf_property`, `perseus.smurf`, `perseus.property`, `perseus.display_layout` (base tables, deployed ✅) |
| Blocks | `perseus.combined_field_map_display_type` (Wave 1) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/4.perseus.dbo.combined_sp_field_map_display_type.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/4.perseus.combined_sp_field_map_display_type.sql` |

---

## Source Query Analysis

This view is the companion display-type view to `combined_sp_field_map`. It generates synthetic `field_map_display_type` records from `smurf_property` configurations via a five-branch UNION, each representing a specific rendering layout for a different display context:

**Branch 1 — Fatsmurf reading editing** (`id = sp.id + 10000 + dl.id`, `field_map_id = sp.id + 20000`, `display_layout_id = 5`, `dl.id IN (1)`):
Maps to the reading edit form (display_layout 5 = editing layout). CROSS JOINs `display_layout` filtered to `dl.id = 1`.

**Branch 2 — Fatsmurf reading table** (`id = sp.id + 20000 + dl.id`, `field_map_id = sp.id + 20000`, `display_layout_id = 7`, `dl.id IN (7)`):
Table view layout (display_layout 7). CROSS JOIN filtered to `dl.id = 7`.

**Branch 3 — Fatsmurf listing** (`id = sp.id + 30000 + dl.id`, `field_map_id = sp.id + 30000`, `display_layout_id = 7`, `dl.id IN (3)`):
List context, using `getPollValueStringBySmurfPropertyId` (returns a formatted string, not a raw value). CROSS JOIN filtered to `dl.id = 3`.

**Branch 4 — Fatsmurf CSV** (`id = sp.id + 40000 + dl.id`, `field_map_id = sp.id + 30000`, `display_layout_id = 7`, `dl.id IN (6)`):
CSV context, also uses `getPollValueStringBySmurfPropertyId`. Note: `field_map_id = sp.id + 30000` (same block as Branch 3 — both CSV and listing map to the same field_map block).

**Branch 5 — Fatsmurf single reading editing** (`id = sp.id + 50000 + dl.id`, `field_map_id = sp.id + 40000`, `display_layout_id = 5`, `dl.id IN (1)`):
Single-reading edit form, maps to field_map block id+40000.

**Key observations:**
- All five branches use a CROSS JOIN to `display_layout`, but each filters `dl.id IN (single_value)`. A CROSS JOIN to a table filtered to a single row is effectively just providing access to the `dl.id` value for the composite ID calculation. The `WHERE sp.disabled = 0` filter is applied in every branch.
- The `CROSS JOIN ... WHERE dl.id IN (n)` pattern is functionally equivalent to a subquery `SELECT dl.id FROM display_layout WHERE id = n` but is written as a CROSS JOIN for simplicity. This is valid.
- The `display` column uses two different PHP method calls: `getPollValueBySmurfPropertyId` (returns single raw value) for Branches 1, 2, 5 and `getPollValueStringBySmurfPropertyId` (returns formatted string) for Branches 3, 4.
- `manditory` (sic — intentional misspelling from T-SQL original) must be preserved exactly in the output column name for backward compatibility with application code.
- The SCT output contains an orphan comment `/* fatsmurf reading editing */` after the semicolon — must be removed.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.combined_sp_field_map_display_type` with all references under `perseus_dbo`. All base tables are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — `WITH SCHEMABINDING` clause must be removed

**Severity:** P2
**Location:** T-SQL original — `CREATE VIEW combined_sp_field_map_display_type WITH SCHEMABINDING AS`
**Description:** SQL Server-only clause — not supported in PostgreSQL. AWS SCT correctly strips this.
**Fix:** Remove `WITH SCHEMABINDING`. AWS SCT handles this.

---

#### P2-02 — `+` string concatenation → `||` operator

**Severity:** P2
**Location:** All five branches — `display` column: `'getPollValueBySmurfPropertyId(' + CONVERT(VARCHAR(25), sp.id) + ')'`
**Description:** T-SQL uses `+` for string concatenation. PostgreSQL uses `||`. AWS SCT correctly converts all occurrences.
**Fix:** AWS SCT handles this.

---

#### P2-03 — `CONVERT(VARCHAR(25), sp.id)` → `sp.id::TEXT`

**Severity:** P2
**Location:** All five branches — `display` column expression
**Description:** `CONVERT` is SQL Server-only. AWS SCT converts to `CAST(sp.id AS VARCHAR(25))` which is valid PostgreSQL ANSI CAST syntax. Production DDL can use `sp.id::TEXT` (idiomatic PostgreSQL).
**Fix:** AWS SCT handles this. Prefer `sp.id::TEXT` in production DDL.

---

#### P2-04 — `manditory` column name — intentional misspelling, must be preserved

**Severity:** P2 (awareness — not a bug to fix)
**Location:** All five branches — `0 AS manditory`
**Description:** The column name `manditory` is a misspelling of "mandatory" — this misspelling is present in the original T-SQL and in the base `field_map_display_type` table column definition. Correcting the spelling would break application code that references this column by name. The misspelling MUST be preserved in the production DDL.
**Fix:** Do not correct — retain `manditory` as the column name.

---

#### P2-05 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.combined_sp_field_map_display_type IS '...'`.

---

#### P2-06 — Orphan comment at end of SCT output

**Severity:** P2 (minor)
**Location:** AWS SCT output — last line: `/* fatsmurf reading editing */`
**Description:** SCT moved the first branch comment to after the semicolon. Remove in production DDL.
**Fix:** Remove misplaced comment.

---

### P3 Issues

#### P3-01 — UNION vs UNION ALL — confirm deduplication intent

**Severity:** P3 (design validation)
**Location:** Between all five branches
**Description:** The `id` values across branches use different base offsets (10000, 20000, 30000, 40000, 50000), making cross-branch duplicates structurally impossible for distinct `sp.id` values. `UNION ALL` would avoid the deduplication sort but changes the semantic contract. Retain `UNION` for fidelity.

---

#### P3-02 — `CROSS JOIN display_layout WHERE dl.id IN (n)` pattern

**Severity:** P3 (design note)
**Location:** All five branches
**Description:** The CROSS JOIN to `display_layout` filtered to a single `dl.id` value is an indirect way to include `dl.id` in the `id` calculation. It implicitly depends on `display_layout` having at least one row for each expected `id` value (1, 3, 6, 7). If `display_layout` does not contain a row with the expected `dl.id`, that branch produces zero rows — silent data loss. Verify that `display_layout` contains rows for `id IN (1, 3, 6, 7)` on DEV before deployment.
**Fix:** Add a validation query to the unit test: `SELECT id FROM perseus.display_layout WHERE id IN (1, 3, 6, 7)` must return 4 rows.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `WITH SCHEMABINDING` | Remove | CREATE VIEW header | Not supported in PostgreSQL |
| `+` (string concat) | `\|\|` | display column in all branches | AWS SCT handles this |
| `CONVERT(VARCHAR(25), sp.id)` | `sp.id::TEXT` | display column in all branches | AWS SCT uses CAST — both valid |
| `dbo.smurf_property` | `perseus.smurf_property` | All 5 branches | Schema correction |
| `dbo.smurf` | `perseus.smurf` | All 5 branches | Schema correction |
| `dbo.property` | `perseus.property` | All 5 branches | Schema correction |
| `dbo.display_layout` | `perseus.display_layout` | All 5 branches (CROSS JOIN) | Schema correction |
| `0 AS manditory` | `0 AS manditory` | All 5 branches | Preserve intentional misspelling |
| Orphan comment `/* fatsmurf reading editing */` | Remove | After semicolon in SCT output | Clean up SCT artifact |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.combined_sp_field_map_display_type IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`4.perseus.combined_sp_field_map_display_type.sql`) key characteristics:
- `WITH SCHEMABINDING` removed — ✅
- `+` converted to `||` — ✅
- `CONVERT(VARCHAR(25), sp.id)` → `CAST(sp.id AS VARCHAR(25))` — ✅
- `manditory` column preserved — ✅
- CROSS JOIN preserved — ✅
- Schema `perseus_dbo` — WRONG (P1-01)
- Orphan comment `/* fatsmurf reading editing */` after semicolon — minor defect (P2-06)
- No `COMMENT ON VIEW` — missing (P2-05)

**SCT reliability score: 7/10**
All syntactic transformations are correct. Schema name is the only material defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.combined_sp_field_map_display_type
-- Description: Generates synthetic field_map_display_type records from
--              smurf_property definitions. Five branches represent different
--              display layout contexts:
--              Branch 1 (id=sp+10000+dl, map=sp+20000, layout=5): Reading edit form
--              Branch 2 (id=sp+20000+dl, map=sp+20000, layout=7): Reading table view
--              Branch 3 (id=sp+30000+dl, map=sp+30000, layout=7): Listing context
--              Branch 4 (id=sp+40000+dl, map=sp+30000, layout=7): CSV context
--              Branch 5 (id=sp+50000+dl, map=sp+40000, layout=5): Single read edit
--
--              NOTE: Column 'manditory' is an intentional misspelling preserved from
--              the T-SQL original for application backward compatibility.
--
--              PREREQUISITE: display_layout must contain rows for id IN (1, 3, 6, 7).
--
-- Depends on:  perseus.smurf_property (base table ✅)
--              perseus.smurf (base table ✅)
--              perseus.property (base table ✅)
--              perseus.display_layout (base table ✅)
-- Blocks:      perseus.combined_field_map_display_type (Wave 1)
-- Wave:        Wave 0
-- T-SQL ref:   dbo.combined_sp_field_map_display_type
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_sp_field_map_display_type (
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
) AS

-- Branch 1: Fatsmurf reading editing (getPollValue, layout=5, dl.id=1)
SELECT
    sp.id + 10000 + dl.id                                              AS id,
    sp.id + 20000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueBySmurfPropertyId(' || sp.id::TEXT || ')'             AS display,
    5                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (1)

UNION

-- Branch 2: Fatsmurf reading table (getPollValue, layout=7, dl.id=7)
SELECT
    sp.id + 20000 + dl.id                                              AS id,
    sp.id + 20000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueBySmurfPropertyId(' || sp.id::TEXT || ')'             AS display,
    7                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (7)

UNION

-- Branch 3: Fatsmurf listing (getPollValueString, layout=7, dl.id=3)
SELECT
    sp.id + 30000 + dl.id                                              AS id,
    sp.id + 30000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueStringBySmurfPropertyId(' || sp.id::TEXT || ')'       AS display,
    7                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (3)

UNION

-- Branch 4: Fatsmurf CSV (getPollValueString, layout=7, dl.id=6, field_map_id=sp+30000)
SELECT
    sp.id + 40000 + dl.id                                              AS id,
    sp.id + 30000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueStringBySmurfPropertyId(' || sp.id::TEXT || ')'       AS display,
    7                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (6)

UNION

-- Branch 5: Fatsmurf single reading editing (getPollValue, layout=5, dl.id=1, field_map_id=sp+40000)
SELECT
    sp.id + 50000 + dl.id                                              AS id,
    sp.id + 40000                                                      AS field_map_id,
    dl.id                                                              AS display_type_id,
    'getPollValueBySmurfPropertyId(' || sp.id::TEXT || ')'             AS display,
    5                                                                  AS display_layout_id,
    0                                                                  AS manditory
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON s.id = sp.smurf_id
JOIN perseus.property AS p
    ON p.id = sp.property_id
CROSS JOIN perseus.display_layout AS dl
WHERE sp.disabled = 0
  AND dl.id IN (1);

-- Documentation
COMMENT ON VIEW perseus.combined_sp_field_map_display_type IS
    'Generates synthetic field_map_display_type rows for 5 smurf_property display contexts. '
    'Uses CROSS JOIN to display_layout filtered by dl.id to derive composite id values. '
    'Column ''manditory'' (intentional misspelling) preserved for application compatibility. '
    'Prerequisite: display_layout must contain id IN (1, 3, 6, 7). '
    'Combined with field_map_display_type base table in combined_field_map_display_type (Wave 1). '
    'Depends on: smurf_property, smurf, property, display_layout. '
    'T-SQL source: dbo.combined_sp_field_map_display_type | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9.5/10 | Five-branch UNION with CROSS JOIN. All constructs valid PostgreSQL 17. |
| Logic Preservation | 9/10 | All five branches preserved. `sp.id::TEXT` equivalent to `CAST(sp.id AS VARCHAR(25))`. Misspelling `manditory` preserved. |
| Performance | 6.5/10 | Five identical three-table JOINs plus CROSS JOIN per branch. UNION deduplication adds overhead. Performance depends on `smurf_property` table size and index coverage. The `sp.disabled = 0` filter benefits from a partial index or index on `disabled`. |
| Maintainability | 8.5/10 | Clear branch comments, explicit column alias list, COMMENT ON VIEW. The `manditory` misspelling is documented. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no user-input injection risk. |
| **Overall** | **8.6/10** | Exceeds PROD target (8.0). |

---

## Pre-Deployment Validation Query

```sql
-- Verify display_layout has required rows before deploying this view
SELECT id FROM perseus.display_layout WHERE id IN (1, 3, 6, 7) ORDER BY id;
-- Expected: 4 rows (1, 3, 6, 7). Any missing row causes a branch to return 0 rows.
```

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 1.0 hour |
| Risk | Low |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.25 h — Schema correction across 20 table references (5 branches × 4 tables)
- 0.25 h — Verify `||` concat, `::TEXT` casts, `manditory` spelling, remove orphan comment
- 0.25 h — Add column alias list to CREATE VIEW header, add COMMENT ON VIEW
- 0.25 h — Syntax validation with `psql`, run pre-deployment validation query on DEV

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
