# Analysis: vw_recipe_prep_part (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_recipe_prep_part` |
| PostgreSQL name | `perseus.vw_recipe_prep_part` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 5/10 |
| Wave | Wave 2 (depends on both `vw_lot` AND `vw_lot_edge`) |
| Depends on | `perseus.vw_lot` (Wave 0), `perseus.vw_lot_edge` (Wave 1), `perseus.recipe` (base table ✅), `perseus.recipe_part` (base table ✅) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/20.perseus.dbo.vw_recipe_prep_part.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/20.perseus.vw_recipe_prep_part.sql` |

---

## Source Query Analysis

This is the most complex Wave 2 view — the only view that must wait for both Wave 0 (`vw_lot`) and Wave 1 (`vw_lot_edge`) to be deployed. It joins five instances of views and base tables to expose recipe part split information.

**Join chain:**
1. `vw_lot split` — the split lot (the material that was split to become a recipe ingredient)
2. `vw_lot_edge split_to_prep ON split_to_prep.src_lot_id = split.id` — the edge from the split lot to the prep lot
3. `vw_lot prep ON prep.id = split_to_prep.dst_lot_id` — the prep lot (the recipe preparation container)
4. `vw_lot_edge src_to_split ON src_to_split.dst_lot_id = split.id` — the edge from the source lot to the split lot
5. `vw_lot src ON src.id = src_to_split.src_lot_id` — the source lot (the original material before splitting)
6. `recipe r ON r.id = prep.recipe_id` — the recipe associated with the prep lot
7. `recipe_part rp ON rp.id = split.recipe_part_id AND r.id = rp.recipe_id` — the recipe part that the split lot corresponds to

**Business logic interpretation:**
A recipe preparation involves:
- A source lot (`src`) — the original material stock
- A split lot (`split`) — a portion of the source lot that was split off to be used as a specific recipe part
- A prep lot (`prep`) — the recipe preparation output lot

The view identifies which split lot was used for which recipe part (`rp`) of which recipe (`r`), and what the original source lot was. Both the split lot and the prep lot must have specific process types:
- `split.process_type_id = 110` — split/dispensing process type
- `prep.process_type_id = 207` — recipe preparation process type

**Column output (11 columns):**
`id` (split.id), `recipe_id`, `recipe_part_id`, `prep_id` (prep.id), `expected_material_type_id` (from recipe_part), `actual_material_type_id` (from split), `source_lot_id` (src.id), `volume_l` (split.original_volume), `mass_kg` (split.original_mass), `created_on` (split.created_on), `created_by_id` (split.created_by_id)

**Key observations:**
- `vw_lot` is referenced three times (`split`, `prep`, `src`) — three full evaluations of the vw_lot query (three three-table JOINs each). This is the primary performance concern.
- `vw_lot_edge` is referenced twice (`split_to_prep`, `src_to_split`) — two full evaluations.
- All JOINs are INNER JOINs — rows are only returned when all five lot/edge instances match.
- The double-quote quoting in T-SQL (`CREATE VIEW "vw_recipe_prep_part"`) requires no quoting in PostgreSQL.
- `volume_L` → `volume_l` case-folding (same as `vw_recipe_prep`).
- `recipe.id` and `recipe_part.id` are INTEGER — join conditions `r.id = prep.recipe_id` and `rp.id = split.recipe_part_id` are INTEGER/INTEGER (assuming `vw_lot.recipe_id` and `vw_lot.recipe_part_id` are INTEGER from `goo.recipe_id` and `goo.recipe_part_id`).

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_recipe_prep_part` with all object references under `perseus_dbo`. All views and tables (`vw_lot`, `vw_lot_edge`, `recipe`, `recipe_part`) are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — Column alias case: `volume_L` → `volume_l`

**Severity:** P2 (awareness — PostgreSQL behavior)
**Location:** SELECT list — `split.original_volume AS volume_L`
**Description:** Same as `vw_recipe_prep` — PostgreSQL folds unquoted identifiers to lowercase. `volume_L` becomes `volume_l` in the output. AWS SCT already uses lowercase `volume_l`.
**Fix:** Use `volume_l` (lowercase) in production DDL.

---

#### P2-02 — Performance: `vw_lot` evaluated three times, `vw_lot_edge` evaluated twice

**Severity:** P2 (performance risk — not a correctness issue)
**Location:** FROM clause
**Description:** `vw_lot` is a three-table JOIN (goo × transition_material × fatsmurf). When referenced three times, PostgreSQL will evaluate this underlying JOIN three times (once per alias: `split`, `prep`, `src`). Similarly, `vw_lot_edge` references `material_transition × vw_lot × vw_lot` — evaluated twice (`split_to_prep`, `src_to_split`). The total underlying table access count is:
- From `split` alias: goo + transition_material + fatsmurf = 3 scans
- From `prep` alias: goo + transition_material + fatsmurf = 3 scans
- From `src` alias: goo + transition_material + fatsmurf = 3 scans
- From `split_to_prep` (vw_lot_edge): material_transition + vw_lot × 2 = material_transition + 6 more table scans
- From `src_to_split` (vw_lot_edge): same = 7 more table scans

PostgreSQL's query planner may or may not fold these redundant scans. Use EXPLAIN ANALYZE to assess. If performance is inadequate, consider creating a dedicated materialized view.

**Fix:** Post-deployment EXPLAIN ANALYZE required. Flag for performance review. If the plan is poor, consider materializing `vw_lot` as a separate table for this view's use.

---

#### P2-03 — Double-quote identifier quoting in T-SQL original

**Severity:** P2 (informational)
**Location:** T-SQL original — `CREATE VIEW "vw_recipe_prep_part" AS`
**Description:** ANSI double-quote quoting — not needed in PostgreSQL.
**Fix:** `CREATE OR REPLACE VIEW perseus.vw_recipe_prep_part AS` (no quotes).

---

#### P2-04 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_recipe_prep_part IS '...'`.

---

### P3 Issues

#### P3-01 — Verify `recipe` and `recipe_part` table schema qualification in T-SQL

**Severity:** P3 (informational)
**Location:** T-SQL original — `JOIN recipe r`, `JOIN recipe_part rp` (no schema prefix)
**Description:** Requires `JOIN perseus.recipe AS r` and `JOIN perseus.recipe_part AS rp` in PostgreSQL. AWS SCT handles this (wrong schema, corrected manually).

---

#### P3-02 — `recipe_part.goo_type_id` column name verification

**Severity:** P3 (validation)
**Location:** `rp.goo_type_id AS expected_material_type_id`
**Description:** Verify `recipe_part` table has a column named `goo_type_id`. Run `\d perseus.recipe_part` on DEV.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW "vw_recipe_prep_part" AS` | `CREATE OR REPLACE VIEW perseus.vw_recipe_prep_part AS` | DDL header | Remove quotes, schema prefix, OR REPLACE |
| `FROM vw_lot split` | `FROM perseus.vw_lot AS split` | FROM clause | Schema + AS keyword |
| `JOIN vw_lot_edge split_to_prep ...` | `JOIN perseus.vw_lot_edge AS split_to_prep ...` | JOIN | Schema + AS |
| `JOIN vw_lot prep ...` | `JOIN perseus.vw_lot AS prep ...` | JOIN | Schema + AS |
| `JOIN vw_lot_edge src_to_split ...` | `JOIN perseus.vw_lot_edge AS src_to_split ...` | JOIN | Schema + AS |
| `JOIN vw_lot src ...` | `JOIN perseus.vw_lot AS src ...` | JOIN | Schema + AS |
| `JOIN recipe r ...` | `JOIN perseus.recipe AS r ...` | JOIN | Schema + AS |
| `JOIN recipe_part rp ...` | `JOIN perseus.recipe_part AS rp ...` | JOIN | Schema + AS |
| `split.original_volume AS volume_L` | `split.original_volume AS volume_l` | SELECT list | Lowercase L |
| `perseus_dbo.*` (SCT output) | `perseus.*` | All references | Schema correction |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_recipe_prep_part IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`20.perseus.vw_recipe_prep_part.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_recipe_prep_part (id, recipe_id, recipe_part_id, prep_id, expected_material_type_id, actual_material_type_id, source_lot_id, volume_l, mass_kg, created_on, created_by_id) AS
SELECT
    split.id AS id, r.id AS recipe_id, rp.id AS recipe_part_id, prep.id AS prep_id, rp.goo_type_id AS expected_material_type_id, split.material_type_id AS actual_material_type_id, src.id AS source_lot_id, split.original_volume AS volume_l, split.original_mass AS mass_kg, split.created_on, split.created_by_id
    FROM perseus_dbo.vw_lot AS split
    JOIN perseus_dbo.vw_lot_edge AS split_to_prep
        ON split_to_prep.src_lot_id = split.id
    JOIN perseus_dbo.vw_lot AS prep
        ON prep.id = split_to_prep.dst_lot_id
    JOIN perseus_dbo.vw_lot_edge AS src_to_split
        ON src_to_split.dst_lot_id = split.id
    JOIN perseus_dbo.vw_lot AS src
        ON src.id = src_to_split.src_lot_id
    JOIN perseus_dbo.recipe AS r
        ON r.id = prep.recipe_id
    JOIN perseus_dbo.recipe_part AS rp
        ON rp.id = split.recipe_part_id AND r.id = rp.recipe_id
    WHERE split.recipe_part_id IS NOT NULL AND prep.recipe_id IS NOT NULL AND split.process_type_id = 110 AND prep.process_type_id = 207;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added full 11-column alias list in header — correct.
- Removed ANSI double quotes from view name — correct.
- Added `AS` keyword for all table aliases — correct.
- Correctly lowercased `volume_L` to `volume_l` — correct.
- Preserved all seven join conditions faithfully — correct.
- Preserved the multi-condition WHERE clause — correct.
- No T-SQL-specific syntax to convert.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.
3. Single-line SELECT column list — readability only.

**SCT reliability score: 8/10**
Cleanest possible SCT output for a complex multi-join view. Schema name is the only material defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_recipe_prep_part
-- Description: Recipe preparation part details. Identifies which split lot was
--              used for which recipe part in which recipe preparation.
--
--              Join chain (5 lot/edge instances + 2 base tables):
--              split      — the dispensed/split lot (process_type_id = 110)
--              split_to_prep — edge from split lot to prep lot
--              prep       — the recipe preparation lot (process_type_id = 207)
--              src_to_split  — edge from source lot to split lot
--              src        — the original source material lot
--              recipe r   — the recipe associated with prep.recipe_id
--              recipe_part rp — the part specification matching split.recipe_part_id
--
--              Column semantics:
--              id                        — split lot id (goo.id)
--              recipe_id                 — recipe.id associated with the prep lot
--              recipe_part_id            — recipe_part.id for this split
--              prep_id                   — prep lot id (goo.id)
--              expected_material_type_id — goo_type_id from recipe_part (spec)
--              actual_material_type_id   — goo_type_id from split lot (actual)
--              source_lot_id             — src lot id (original material stock)
--              volume_l                  — split.original_volume (liters)
--              mass_kg                   — split.original_mass (kilograms)
--
--              NOTE: 'volume_l' is lowercase (PostgreSQL case-folds 'volume_L').
--
--              PERFORMANCE: vw_lot evaluated 3x, vw_lot_edge 2x on each query.
--              Run EXPLAIN ANALYZE post-deployment. Consider materializing vw_lot
--              if plan cost is excessive.
--
-- Depends on:  perseus.vw_lot (Wave 0 view)
--              perseus.vw_lot_edge (Wave 1 view — must be deployed before this view)
--              perseus.recipe (base table ✅)
--              perseus.recipe_part (base table ✅)
-- Blocks:      None
-- Wave:        Wave 2 (last wave — requires both Wave 0 and Wave 1)
-- T-SQL ref:   dbo.vw_recipe_prep_part
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_recipe_prep_part (
    id,
    recipe_id,
    recipe_part_id,
    prep_id,
    expected_material_type_id,
    actual_material_type_id,
    source_lot_id,
    volume_l,
    mass_kg,
    created_on,
    created_by_id
) AS
SELECT
    split.id                         AS id,
    r.id                             AS recipe_id,
    rp.id                            AS recipe_part_id,
    prep.id                          AS prep_id,
    rp.goo_type_id                   AS expected_material_type_id,
    split.material_type_id           AS actual_material_type_id,
    src.id                           AS source_lot_id,
    split.original_volume            AS volume_l,
    split.original_mass              AS mass_kg,
    split.created_on,
    split.created_by_id
FROM perseus.vw_lot AS split
JOIN perseus.vw_lot_edge AS split_to_prep
    ON split_to_prep.src_lot_id = split.id
JOIN perseus.vw_lot AS prep
    ON prep.id = split_to_prep.dst_lot_id
JOIN perseus.vw_lot_edge AS src_to_split
    ON src_to_split.dst_lot_id = split.id
JOIN perseus.vw_lot AS src
    ON src.id = src_to_split.src_lot_id
JOIN perseus.recipe AS r
    ON r.id = prep.recipe_id
JOIN perseus.recipe_part AS rp
    ON rp.id = split.recipe_part_id
   AND r.id = rp.recipe_id
WHERE split.recipe_part_id IS NOT NULL
  AND prep.recipe_id IS NOT NULL
  AND split.process_type_id = 110
  AND prep.process_type_id = 207;

-- Documentation
COMMENT ON VIEW perseus.vw_recipe_prep_part IS
    'Recipe preparation part details. Joins split lot → prep lot → source lot via '
    'vw_lot_edge, then maps to recipe and recipe_part for expected/actual material type comparison. '
    'Split lot: process_type_id=110 (dispensing). Prep lot: process_type_id=207 (recipe prep). '
    'Column ''volume_l'' lowercase: PostgreSQL case-folds unquoted ''volume_L''. '
    'PERFORMANCE: vw_lot evaluated 3x, vw_lot_edge 2x per query. Run EXPLAIN ANALYZE post-deploy. '
    'Wave 2 (last): requires vw_lot (Wave 0) and vw_lot_edge (Wave 1) to be deployed first. '
    'Depends on: vw_lot, vw_lot_edge (views), recipe, recipe_part (base tables). '
    'T-SQL source: dbo.vw_recipe_prep_part | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Seven-table JOIN with multi-condition WHERE. All constructs valid PostgreSQL 17. |
| Logic Preservation | 9.5/10 | All seven join conditions and four WHERE predicates preserved. `volume_L` → `volume_l` is correct PostgreSQL behavior. |
| Performance | 6/10 | Three `vw_lot` evaluations and two `vw_lot_edge` evaluations are the main risk. Each `vw_lot` instance requires a three-table JOIN. The planner may or may not apply optimization across repeated view references. EXPLAIN ANALYZE is mandatory before STAGING deployment. Score reflects the inherent complexity of the original design — not a migration defect. |
| Maintainability | 9/10 | Comprehensive COMMENT ON VIEW with join chain and column semantics. Performance risk documented. Schema-qualified. Clear WHERE conditions separated onto individual lines. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **8.8/10** | Exceeds STAGING gate (7.0+). Performance review is mandatory before PROD deployment. |

---

## Performance Mitigation Options (Post-Deployment)

If EXPLAIN ANALYZE shows excessive cost:

**Option A — Materialize `vw_lot`:**
```sql
CREATE MATERIALIZED VIEW perseus.mv_lot AS SELECT * FROM perseus.vw_lot;
CREATE UNIQUE INDEX idx_mv_lot_id ON perseus.mv_lot(id);
CREATE INDEX idx_mv_lot_uid ON perseus.mv_lot(uid);
CREATE INDEX idx_mv_lot_process_uid ON perseus.mv_lot(process_uid);
```
Then rewrite `vw_recipe_prep_part` to reference `perseus.mv_lot` instead of `perseus.vw_lot`.

**Option B — Materialize `vw_recipe_prep_part` itself:**
If this view is read frequently but the underlying data changes infrequently (recipe preparations are batch operations), consider converting it to a materialized view with a refresh trigger on `material_transition` / `goo` changes.

---

## Pre-Deployment Validation Queries

```sql
-- Verify recipe_part.goo_type_id column exists
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'perseus' AND table_name = 'recipe_part' AND column_name = 'goo_type_id';

-- Spot check: count recipe prep parts after deployment
SELECT COUNT(*) FROM perseus.vw_recipe_prep_part;

-- Performance check
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM perseus.vw_recipe_prep_part LIMIT 100;
```

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.75 hours |
| Risk | Medium |
| Blocker | `perseus.vw_lot` (Wave 0) AND `perseus.vw_lot_edge` (Wave 1) must both be deployed first |

**Effort breakdown:**
- 0.2 h — Schema correction across 7 object references, verify `volume_l` lowercase
- 0.1 h — Verify `recipe_part.goo_type_id` column on DEV
- 0.2 h — Format multi-join DDL with clear column list, add COMMENT ON VIEW
- 0.25 h — Syntax validation, EXPLAIN ANALYZE post-deployment, record quality score

**Risk: Medium** — Performance is the primary concern due to repeated `vw_lot` evaluations. Must be benchmarked on realistic data before STAGING deployment.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
