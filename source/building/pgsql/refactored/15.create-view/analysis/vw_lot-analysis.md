# Analysis: vw_lot (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_lot` |
| PostgreSQL name | `perseus.vw_lot` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 5/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.goo`, `perseus.transition_material`, `perseus.fatsmurf` (base tables, deployed ✅) |
| Blocks | `perseus.vw_lot_edge` (Wave 1), `perseus.vw_lot_path` (Wave 1), `perseus.vw_recipe_prep` (Wave 1), `perseus.vw_recipe_prep_part` (Wave 2) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/13.perseus.dbo.vw_lot.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/13.perseus.vw_lot.sql` |

---

## Source Query Analysis

This is a high-importance foundational view. It joins `goo` (the material table, aliased `m`) to `transition_material` and `fatsmurf` (the process table, aliased `p`) via a LEFT JOIN chain. The business semantics are:

- Each row in `goo` represents a lot (material). A lot may or may not have been produced by a process step.
- `transition_material` links a `transition_id` (a process/fatsmurf uid) to a `material_id` (goo uid).
- `fatsmurf` is the process table — `p.uid` matches `tm.transition_id` to bring process attributes onto the lot row.
- The LEFT JOINs mean materials without a linked process appear with NULL process columns — correct for materials that are "root" inputs with no associated fatsmurf process.

Two CASE expressions implement business logic:
1. `container_id`: prefer the process container if set, fall back to the material container.
2. `manufacturer_id`: use material manufacturer if set, otherwise fall back to process organization.

The view exposes `m.uid` (TEXT — goo unique identifier) and `p.uid` (TEXT — fatsmurf uid as process_uid), both used as join keys by dependent views.

The T-SQL original uses double-quote quoting `CREATE VIEW "vw_lot"` — a valid ANSI SQL identifier quoting form that PostgreSQL also supports. The column headers use `m.added_on AS created_on` and `m.added_by AS created_by_id` — mapping goo's audit columns to standard names.

**Critical note for dependent views:** `vw_lot_edge` joins on `sl.uid = mt.material_id` (goo uid = material_transition material_id) and `dl.process_uid = mt.transition_id` (fatsmurf uid = material_transition transition_id). The `uid` and `process_uid` columns exposed by this view are the join keys for the downstream wave.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_lot` with all table references under `perseus_dbo`. All base tables (`goo`, `transition_material`, `fatsmurf`) are deployed under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — `LEFT OUTER JOIN` → `LEFT JOIN` (style)

**Severity:** P2 (style only — functionally equivalent)
**Location:** Both LEFT JOIN clauses
**Description:** `LEFT OUTER JOIN` is valid ANSI SQL but verbose. The `OUTER` keyword is redundant. AWS SCT preserves this verbosity; production DDL should use `LEFT JOIN`.
**Fix:** Use `LEFT JOIN` (drop `OUTER` keyword).

---

#### P2-02 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output. This view is foundational and blocks four dependent views — it especially warrants documentation.
**Fix:** Add `COMMENT ON VIEW perseus.vw_lot IS '...'`.

---

#### P2-03 — Double-quote identifier quoting in T-SQL original

**Severity:** P2 (informational — PostgreSQL supports ANSI quoting)
**Location:** T-SQL original — `CREATE VIEW "vw_lot" AS`
**Description:** The T-SQL uses ANSI double-quote quoting, which PostgreSQL also supports. In the production DDL, the view name is lowercase snake_case and does not require quoting. Use unquoted `vw_lot` in the CREATE OR REPLACE VIEW statement.
**Fix:** `CREATE OR REPLACE VIEW perseus.vw_lot AS` (no quotes needed).

---

### P3 Issues

#### P3-01 — Mixed case `as` keyword in T-SQL original

**Severity:** P3 (style — handled in production DDL formatting)
**Location:** T-SQL original — `p.smurf_id as process_type_id` (lowercase `as`)
**Description:** T-SQL is case-insensitive. Use consistent uppercase `AS` in PostgreSQL DDL per constitution style.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW "vw_lot" AS` | `CREATE OR REPLACE VIEW perseus.vw_lot AS` | DDL header | Schema prefix, drop quotes, add OR REPLACE |
| `FROM goo m` (unqualified) | `FROM perseus.goo AS m` | FROM clause | Explicit schema + AS keyword |
| `LEFT OUTER JOIN transition_material tm` | `LEFT JOIN perseus.transition_material AS tm` | JOIN clause | Schema + drop OUTER |
| `LEFT OUTER JOIN fatsmurf p` | `LEFT JOIN perseus.fatsmurf AS p` | JOIN clause | Schema + drop OUTER |
| `p.smurf_id as process_type_id` | `p.smurf_id AS process_type_id` | SELECT list | Uppercase AS |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_lot IS '...'` | Post-CREATE | Constitution Article VI |
| `perseus_dbo.*` (SCT output) | `perseus.*` | All references | Schema correction in SCT output |

---

## AWS SCT Assessment

AWS SCT output (`13.perseus.vw_lot.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_lot (id, uid, name, description, material_type_id, process_id, process_uid, process_name, process_description, process_type_id, run_on, duration, container_id, original_volume, original_mass, triton_task_id, recipe_id, recipe_part_id, manufacturer_id, themis_sample_id, catalog_label, created_on, created_by_id) AS
SELECT
    m.id, m.uid, m.name, m.description, m.goo_type_id AS material_type_id, p.id AS process_id, p.uid AS process_uid, p.name AS process_name, p.description AS process_description, p.smurf_id AS process_type_id, p.run_on, p.duration,
    CASE
        WHEN p.container_id IS NOT NULL THEN p.container_id
        ELSE m.container_id
    END AS container_id, m.original_volume, m.original_mass, m.triton_task_id, m.recipe_id, m.recipe_part_id,
    CASE
        WHEN m.manufacturer_id IS NULL THEN p.organization_id
        ELSE m.manufacturer_id
    END AS manufacturer_id, p.themis_sample_id, m.catalog_label, m.added_on AS created_on, m.added_by AS created_by_id
    FROM perseus_dbo.goo AS m
    LEFT OUTER JOIN perseus_dbo.transition_material AS tm
        ON tm.material_id = m.uid
    LEFT OUTER JOIN perseus_dbo.fatsmurf AS p
        ON tm.transition_id = p.uid;
```

**What SCT got right:**
- Removed ANSI double quotes from view name — correct.
- Added `CREATE OR REPLACE` — idempotent.
- Added full column alias list in header (all 23 columns) — good documentation.
- Preserved all CASE expressions faithfully.
- Correctly identified all column mappings (`added_on` → `created_on`, `added_by` → `created_by_id`).
- No T-SQL-specific syntax in body to convert.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.
3. `LEFT OUTER JOIN` retained — minor style issue.
4. Single-line SELECT column list — readability concern only.

**SCT reliability score: 7/10**
Logic is fully correct. Schema name is the only material defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_lot
-- Description: Foundational lot view. Joins goo (material) to fatsmurf (process)
--              via transition_material to expose lot attributes alongside their
--              producing process attributes. LEFT JOINs ensure materials without
--              an associated process step appear with NULL process columns.
--
--              Business rules applied:
--              - container_id: process container preferred over material container
--              - manufacturer_id: material manufacturer preferred over process org
--
--              Key columns for downstream joins:
--              - uid        (goo.uid, TEXT) — used by vw_lot_edge ON sl.uid = mt.material_id
--              - process_uid (fatsmurf.uid, TEXT) — used by vw_lot_edge ON dl.process_uid = mt.transition_id
--
-- Depends on:  perseus.goo (base table ✅)
--              perseus.transition_material (base table ✅)
--              perseus.fatsmurf (base table ✅)
-- Blocks:      perseus.vw_lot_edge, vw_lot_path, vw_recipe_prep (Wave 1)
--              perseus.vw_recipe_prep_part (Wave 2)
-- Wave:        Wave 0
-- T-SQL ref:   dbo.vw_lot
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_lot (
    id,
    uid,
    name,
    description,
    material_type_id,
    process_id,
    process_uid,
    process_name,
    process_description,
    process_type_id,
    run_on,
    duration,
    container_id,
    original_volume,
    original_mass,
    triton_task_id,
    recipe_id,
    recipe_part_id,
    manufacturer_id,
    themis_sample_id,
    catalog_label,
    created_on,
    created_by_id
) AS
SELECT
    m.id,
    m.uid,
    m.name,
    m.description,
    m.goo_type_id                                                        AS material_type_id,
    p.id                                                                 AS process_id,
    p.uid                                                                AS process_uid,
    p.name                                                               AS process_name,
    p.description                                                        AS process_description,
    p.smurf_id                                                           AS process_type_id,
    p.run_on,
    p.duration,
    CASE WHEN p.container_id IS NOT NULL THEN p.container_id
         ELSE m.container_id
    END                                                                  AS container_id,
    m.original_volume,
    m.original_mass,
    m.triton_task_id,
    m.recipe_id,
    m.recipe_part_id,
    CASE WHEN m.manufacturer_id IS NULL THEN p.organization_id
         ELSE m.manufacturer_id
    END                                                                  AS manufacturer_id,
    p.themis_sample_id,
    m.catalog_label,
    m.added_on                                                           AS created_on,
    m.added_by                                                           AS created_by_id
FROM perseus.goo AS m
LEFT JOIN perseus.transition_material AS tm
    ON tm.material_id = m.uid
LEFT JOIN perseus.fatsmurf AS p
    ON tm.transition_id = p.uid;

-- Documentation
COMMENT ON VIEW perseus.vw_lot IS
    'Foundational lot view. Joins goo (material) to fatsmurf (process) via '
    'transition_material. Materials without an associated process appear with NULL '
    'process columns. Applies two business rules: (1) container_id prefers the '
    'process container over the material container; (2) manufacturer_id prefers '
    'the material manufacturer over the process organization. '
    'Foundational for: vw_lot_edge, vw_lot_path, vw_recipe_prep (Wave 1), '
    'vw_recipe_prep_part (Wave 2). '
    'Depends on: goo, transition_material, fatsmurf (base tables). '
    'T-SQL source: dbo.vw_lot | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Standard ANSI SQL — no complex constructs. |
| Logic Preservation | 9.5/10 | CASE logic preserved exactly. LEFT JOIN NULL semantics documented. Minor deduction for goo.uid ↔ TEXT join type dependency (must be verified against deployed schema). |
| Performance | 7.5/10 | Three-table JOIN (goo × transition_material × fatsmurf). vw_lot is queried multiple times by vw_recipe_prep_part — plan inflation risk. Verify indexes on: goo.uid, transition_material.material_id, fatsmurf.uid. Consider future materialization if this view proves to be a performance bottleneck. |
| Maintainability | 9/10 | 23-column view — column alias list in header aids documentation. COMMENT ON VIEW present. Schema-qualified. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.1/10** | Exceeds PROD target (8.0). Performance must be verified post-deployment given this view is evaluated multiple times in Wave 2. |

---

## Performance Notes

`vw_recipe_prep_part` (Wave 2) joins `vw_lot` three times (aliases: `split`, `prep`, `src`) and `vw_lot_edge` twice. Each evaluation of `vw_lot` involves the three-table JOIN. PostgreSQL's query planner may or may not inline the view multiple times, depending on statistics. After deployment, run:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM perseus.vw_lot LIMIT 100;
```

If `vw_recipe_prep_part` shows excessive cost, the optimizer option is to create a materialized version of `vw_lot` under a different name and redirect the Wave 2 view to use it. This is a deferred optimization concern, not a pre-deployment blocker.

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.5 hours |
| Risk | Low |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.15 h — Schema correction, drop `LEFT OUTER JOIN` → `LEFT JOIN`, remove quote on view name
- 0.15 h — Format 23-column DDL with column alias list, add `COMMENT ON VIEW`
- 0.1 h — Verify index coverage with `\d` on DEV
- 0.1 h — Syntax validation with `psql`, EXPLAIN ANALYZE spot check

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
