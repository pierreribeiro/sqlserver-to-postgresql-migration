# Analysis: vw_recipe_prep (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_recipe_prep` |
| PostgreSQL name | `perseus.vw_recipe_prep` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 3/10 |
| Wave | Wave 1 (depends on `vw_lot`) |
| Depends on | `perseus.vw_lot` (Wave 0 view — must be deployed first) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/19.perseus.dbo.vw_recipe_prep.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/19.perseus.vw_recipe_prep.sql` |

---

## Source Query Analysis

This view filters `vw_lot` to expose only recipe preparation lots. The business logic:
- A recipe preparation lot is one where:
  1. `recipe_id IS NOT NULL` — the lot is associated with a recipe
  2. `process_type_id = 207` — the producing process is of type 207 (recipe preparation step, identified by `fatsmurf.smurf_id = 207`)

The view then projects a reduced column set from `vw_lot`, renaming physical quantity columns:
- `original_volume AS volume_L` — original volume in liters
- `original_mass AS mass_kg` — original mass in kilograms

**Column output (10 columns):**
`id`, `name`, `material_type_id`, `container_id`, `recipe_id`, `triton_task_id`, `volume_L`, `mass_kg`, `created_on`, `created_by_id`

**Key observations:**
- `process_type_id` in `vw_lot` is `p.smurf_id` (the fatsmurf smurf_id). This is an INTEGER comparison (`= 207`). Type consistency with `fatsmurf.smurf_id` (INTEGER) is expected.
- The double-quote quoting `CREATE VIEW "vw_recipe_prep"` in T-SQL is ANSI syntax — no quoting needed in PostgreSQL.
- AWS SCT column alias list uses lowercase: `volume_l`, `mass_kg`. The T-SQL original uses `volume_L` (uppercase L) and `mass_kg`. In PostgreSQL, identifiers are case-folded to lowercase unless quoted. `volume_L` in PostgreSQL becomes `volume_l`. AWS SCT correctly uses lowercase.
- This is one of the simplest views in the migration: no JOINs, no aggregations, no window functions, no T-SQL-specific syntax — just a filtered projection of `vw_lot`.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and `vw_lot` reference
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_recipe_prep` with `FROM perseus_dbo.vw_lot`. Both the view and its `vw_lot` dependency are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — Column alias case: `volume_L` → `volume_l`

**Severity:** P2 (awareness — PostgreSQL behavior)
**Location:** SELECT list — `prep.original_volume AS volume_L`
**Description:** In PostgreSQL, unquoted identifiers are case-folded to lowercase at parse time. `volume_L` becomes `volume_l` in the column alias. This is correct behavior — the AWS SCT output already uses `volume_l` (lowercase) in the column alias list. Application code referencing this column should use lowercase `volume_l`.
**Fix:** Use `volume_l` (lowercase) in production DDL. Do NOT quote as `"volume_L"` (creates a case-sensitive name requiring quoting everywhere).

---

#### P2-02 — `process_type_id = 207` filter — verify type compatibility

**Severity:** P2 (validation)
**Location:** WHERE clause — `prep.process_type_id = 207`
**Description:** `process_type_id` in `vw_lot` comes from `fatsmurf.smurf_id`. Verify `fatsmurf.smurf_id` is INTEGER (not BIGINT or TEXT). If TEXT, the comparison `= 207` will fail or require an implicit cast.
**Fix:** Validate with `SELECT data_type FROM information_schema.columns WHERE table_schema='perseus' AND table_name='fatsmurf' AND column_name='smurf_id';`

---

#### P2-03 — Double-quote identifier quoting in T-SQL original

**Severity:** P2 (informational)
**Location:** T-SQL original — `CREATE VIEW "vw_recipe_prep" AS`
**Description:** ANSI double-quote quoting — not needed for `vw_recipe_prep` in PostgreSQL.
**Fix:** `CREATE OR REPLACE VIEW perseus.vw_recipe_prep AS` (no quotes).

---

#### P2-04 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_recipe_prep IS '...'`.

---

### P3 Issues

#### P3-01 — Unqualified table reference in T-SQL original

**Severity:** P3 (informational)
**Location:** T-SQL original — `FROM vw_lot prep` (no schema prefix)
**Description:** Requires `FROM perseus.vw_lot AS prep` in PostgreSQL. AWS SCT handles this (wrong schema, corrected manually).

---

#### P3-02 — `recipe_id IS NOT NULL` — filter redundancy with `process_type_id = 207`?

**Severity:** P3 (design note)
**Location:** WHERE clause
**Description:** Both conditions are needed independently — a lot can have `recipe_id IS NOT NULL` but `process_type_id != 207` (non-prep recipe step), or vice versa. Both conditions are necessary. Retain as-is.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW "vw_recipe_prep" AS` | `CREATE OR REPLACE VIEW perseus.vw_recipe_prep AS` | DDL header | Remove quotes, add schema + OR REPLACE |
| `FROM vw_lot prep` (unqualified) | `FROM perseus.vw_lot AS prep` | FROM clause | Explicit schema + AS keyword |
| `prep.original_volume AS volume_L` | `prep.original_volume AS volume_l` | SELECT list | Lowercase — PostgreSQL folds identifier case |
| `perseus_dbo.vw_lot` (SCT output) | `perseus.vw_lot` | FROM clause | Schema correction |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_recipe_prep IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`19.perseus.vw_recipe_prep.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_recipe_prep (id, name, material_type_id, container_id, recipe_id, triton_task_id, volume_l, mass_kg, created_on, created_by_id) AS
SELECT
    prep.id, prep.name, prep.material_type_id, prep.container_id, prep.recipe_id, prep.triton_task_id, prep.original_volume AS volume_l, prep.original_mass AS mass_kg, prep.created_on, prep.created_by_id
    FROM perseus_dbo.vw_lot AS prep
    WHERE prep.recipe_id IS NOT NULL AND prep.process_type_id = 207;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added column alias list (10 columns) in header — correct.
- Removed ANSI double quotes from view name — correct.
- Added `AS` keyword for table alias — correct.
- Correctly lowercased `volume_L` to `volume_l` in column alias list — correct PostgreSQL behavior.
- No T-SQL-specific syntax in body to convert.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.

**SCT reliability score: 8/10**
One of the cleanest SCT outputs. Schema name is the only defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_recipe_prep
-- Description: Recipe preparation lots. Filters vw_lot to lots that:
--              1. Are associated with a recipe (recipe_id IS NOT NULL)
--              2. Were produced by a recipe preparation process (process_type_id = 207)
--
--              Exposes a reduced column set from vw_lot:
--              volume_l  — original_volume in liters (lowercase: PostgreSQL case-folding)
--              mass_kg   — original_mass in kilograms
--
--              Used by application code to identify and report on recipe preparation
--              steps within the material lineage.
--
-- Depends on:  perseus.vw_lot (Wave 0 view — must be deployed first)
-- Blocks:      None
-- Wave:        Wave 1
-- T-SQL ref:   dbo.vw_recipe_prep
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_recipe_prep (
    id,
    name,
    material_type_id,
    container_id,
    recipe_id,
    triton_task_id,
    volume_l,
    mass_kg,
    created_on,
    created_by_id
) AS
SELECT
    prep.id,
    prep.name,
    prep.material_type_id,
    prep.container_id,
    prep.recipe_id,
    prep.triton_task_id,
    prep.original_volume   AS volume_l,
    prep.original_mass     AS mass_kg,
    prep.created_on,
    prep.created_by_id
FROM perseus.vw_lot AS prep
WHERE prep.recipe_id IS NOT NULL
  AND prep.process_type_id = 207;

-- Documentation
COMMENT ON VIEW perseus.vw_recipe_prep IS
    'Recipe preparation lots. Filters vw_lot to lots with recipe_id IS NOT NULL '
    'AND process_type_id = 207 (recipe preparation fatsmurf smurf_id). '
    'Projects a reduced column set: volume_l (original_volume), mass_kg (original_mass). '
    'NOTE: column ''volume_l'' uses lowercase ''l'' (PostgreSQL case-folds unquoted identifiers; '
    'T-SQL original used uppercase ''L'' as volume_L). '
    'Depends on: vw_lot (Wave 0 view). '
    'T-SQL source: dbo.vw_recipe_prep | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Single-table filtered projection — minimal syntax. |
| Logic Preservation | 9.5/10 | Both WHERE conditions preserved. `volume_L` → `volume_l` is correct PostgreSQL behavior (not a logic change). Minor deduction: `process_type_id = 207` type compatibility must be confirmed (P2-02). |
| Performance | 8.5/10 | Filtered view of `vw_lot`. PostgreSQL may or may not push the WHERE predicates down through `vw_lot` into the base table scans (depends on planner). If `recipe_id` and `process_type_id` have indexes in the base `goo` and `fatsmurf` tables, performance will be good. Check with EXPLAIN ANALYZE. |
| Maintainability | 9.5/10 | Clear column list, COMMENT ON VIEW explains the case-folding behavior, schema-qualified. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.4/10** | Exceeds PROD target (8.0). Near-trivial conversion. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | `perseus.vw_lot` (Wave 0) must be deployed first |

**Effort breakdown:**
- 0.1 h — Schema correction, remove quotes on view name, verify `volume_l` casing
- 0.1 h — Add `COMMENT ON VIEW` (with case-folding note), column alias list, format DDL
- 0.05 h — Syntax validation with `psql` on DEV, verify `fatsmurf.smurf_id` data type

**Deployment prerequisite:** `perseus.vw_lot` (Wave 0, T038) must be created before this Wave 1 view is deployed.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
