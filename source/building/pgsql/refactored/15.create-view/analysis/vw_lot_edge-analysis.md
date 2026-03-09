# Analysis: vw_lot_edge (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_lot_edge` |
| PostgreSQL name | `perseus.vw_lot_edge` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 4/10 |
| Wave | Wave 1 (depends on `vw_lot`) |
| Depends on | `perseus.material_transition` (base table ✅), `perseus.vw_lot` (Wave 0 view — must be deployed first) |
| Blocks | `perseus.vw_recipe_prep_part` (Wave 2) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/14.perseus.dbo.vw_lot_edge.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/14.perseus.vw_lot_edge.sql` |

---

## Source Query Analysis

This view represents directed edges in the lot lineage graph. It joins `material_transition` to `vw_lot` twice (self-join pattern with different aliases) to expose the source lot and destination lot for each material transition:

- `sl` (source lot): joins on `sl.uid = mt.material_id` — the material that was consumed/started the transition
- `dl` (destination lot): joins on `dl.process_uid = mt.transition_id` — the lot whose producing process (fatsmurf uid) matches the transition's uid

The result is: for each `material_transition` row, find the lot that was the source material (`sl`) and the lot that was the output of the associated process step (`dl`).

**Column output:**
- `src_lot_id`: The integer `id` of the source lot (`goo.id` via `vw_lot.id`)
- `dst_lot_id`: The integer `id` of the destination lot
- `created_on`: The timestamp when the material_transition was recorded (`mt.added_on`)

**Key type observations:**
- `sl.uid` is TEXT (goo.uid), `mt.material_id` is TEXT — join is TEXT/TEXT: correct.
- `dl.process_uid` is TEXT (fatsmurf.uid exposed via vw_lot), `mt.transition_id` is TEXT — join is TEXT/TEXT: correct.
- `sl.id` and `dl.id` are INTEGER (goo.id exposed via vw_lot) — output IDs are integers.
- `mt.added_on` is TIMESTAMPTZ (post-US3 conversion) — `created_on` output is TIMESTAMPTZ.

The INNER JOIN semantics mean only `material_transition` rows that match a lot on both source (`sl.uid`) and destination (`dl.process_uid`) sides appear. Transitions where the destination lot has not yet been created (no matching fatsmurf process) will not appear in the result — this is the intended behavior.

The T-SQL original uses double-quote quoting `CREATE VIEW "vw_lot_edge"` — valid ANSI syntax, no quoting needed in PostgreSQL production DDL.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_lot_edge` with `FROM perseus_dbo.material_transition` and references to `perseus_dbo.vw_lot`. Both the base table and the Wave 0 view are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — Double-quote identifier quoting in T-SQL original

**Severity:** P2 (informational)
**Location:** T-SQL original — `CREATE VIEW "vw_lot_edge" AS`
**Description:** ANSI double-quote quoting used in T-SQL original. `vw_lot_edge` is lowercase snake_case — no quoting needed in PostgreSQL.
**Fix:** `CREATE OR REPLACE VIEW perseus.vw_lot_edge AS` (no quotes).

---

#### P2-02 — `mt.added_on` aliased as `created_on` — verify TIMESTAMPTZ type consistency

**Severity:** P2 (validation)
**Location:** SELECT list — `mt.added_on AS created_on`
**Description:** `material_transition.added_on` was converted to TIMESTAMPTZ during US3. The `created_on` output column will be TIMESTAMPTZ in PostgreSQL. Downstream view `vw_recipe_prep_part` references `split.created_on` and `split.created_by_id` — these come from `vw_lot` (which gets `created_on` from `goo.added_on`), not from this view directly. However, the `created_on` column from `vw_lot_edge` may be joined against TIMESTAMPTZ columns elsewhere. Confirm type consistency.
**Fix:** Verify `material_transition.added_on` is TIMESTAMPTZ on DEV: `SELECT data_type FROM information_schema.columns WHERE table_schema='perseus' AND table_name='material_transition' AND column_name='added_on';`

---

#### P2-03 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_lot_edge IS '...'`.

---

### P3 Issues

#### P3-01 — Inline comment style: `as` vs `AS`

**Severity:** P3 (style)
**Location:** T-SQL original — `mt.added_on as created_on` (lowercase `as`)
**Description:** Production DDL should use uppercase `AS` per constitution style conventions.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW "vw_lot_edge" AS` | `CREATE OR REPLACE VIEW perseus.vw_lot_edge AS` | DDL header | Remove quotes, add schema + OR REPLACE |
| `FROM material_transition mt` | `FROM perseus.material_transition AS mt` | FROM clause | Schema qualification + AS keyword |
| `JOIN vw_lot sl ON ...` | `JOIN perseus.vw_lot AS sl ON ...` | First JOIN | Schema qualification |
| `JOIN vw_lot dl ON ...` | `JOIN perseus.vw_lot AS dl ON ...` | Second JOIN | Schema qualification |
| `mt.added_on as created_on` | `mt.added_on AS created_on` | SELECT list | Uppercase AS |
| `perseus_dbo.*` (SCT output) | `perseus.*` | All references | Schema correction |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_lot_edge IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`14.perseus.vw_lot_edge.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_lot_edge (src_lot_id, dst_lot_id, created_on) AS
SELECT
    sl.id AS src_lot_id, dl.id AS dst_lot_id, mt.added_on AS created_on
    FROM perseus_dbo.material_transition AS mt
    JOIN perseus_dbo.vw_lot AS sl
        ON sl.uid = mt.material_id
    JOIN perseus_dbo.vw_lot AS dl
        ON dl.process_uid = mt.transition_id;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added column alias list `(src_lot_id, dst_lot_id, created_on)` in header — correct.
- Removed ANSI double quotes from view name — correct.
- Added `AS` keyword for table aliases — correct.
- Preserved all join conditions faithfully — correct.
- No T-SQL-specific syntax in body to convert.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.

**SCT reliability score: 8/10**
Cleanest SCT output of any view analyzed so far. Schema name is the only defect. The view body required no functional transformation — pure ANSI SQL.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_lot_edge
-- Description: Directed edges in the lot lineage graph. Each row represents a
--              material transition connecting a source lot to a destination lot.
--
--              src_lot_id: goo.id of the source material lot
--                          (joined via vw_lot.uid = material_transition.material_id)
--              dst_lot_id: goo.id of the destination lot — the lot whose producing
--                          process step (fatsmurf.uid) matches the transition_id
--                          (joined via vw_lot.process_uid = material_transition.transition_id)
--              created_on: TIMESTAMPTZ when the material_transition was recorded
--
--              INNER JOIN semantics: only transitions with matching source AND
--              destination lots appear. Transitions without a completed destination
--              lot are excluded.
--
-- Depends on:  perseus.material_transition (base table ✅)
--              perseus.vw_lot (Wave 0 view — must be deployed first)
-- Blocks:      perseus.vw_recipe_prep_part (Wave 2)
-- Wave:        Wave 1
-- T-SQL ref:   dbo.vw_lot_edge
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_lot_edge (
    src_lot_id,
    dst_lot_id,
    created_on
) AS
SELECT
    sl.id          AS src_lot_id,
    dl.id          AS dst_lot_id,
    mt.added_on    AS created_on
FROM perseus.material_transition AS mt
JOIN perseus.vw_lot AS sl
    ON sl.uid = mt.material_id
JOIN perseus.vw_lot AS dl
    ON dl.process_uid = mt.transition_id;

-- Documentation
COMMENT ON VIEW perseus.vw_lot_edge IS
    'Directed lot lineage graph edges. Each row is a material transition connecting '
    'a source lot (src_lot_id, joined on uid=material_id) to a destination lot '
    '(dst_lot_id, joined on process_uid=transition_id). '
    'INNER JOIN: only transitions with both source and destination lots appear. '
    'created_on (TIMESTAMPTZ) from material_transition.added_on. '
    'Foundational for: vw_recipe_prep_part (Wave 2). '
    'Depends on: material_transition (base table), vw_lot (Wave 0). '
    'T-SQL source: dbo.vw_lot_edge | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Three-table JOIN with self-join on vw_lot. No complex constructs. |
| Logic Preservation | 9.5/10 | Both join conditions faithfully preserved. INNER JOIN semantics documented. Minor deduction: `mt.added_on` TIMESTAMPTZ type (changed in US3) must be verified as consistent with downstream consumers. |
| Performance | 7.5/10 | Double self-join on `vw_lot` — PostgreSQL evaluates `vw_lot` twice (two separate three-table JOINs underneath). If `vw_lot` is expensive, this compounds. Index on `material_transition.material_id` and `material_transition.transition_id` critical. Consider materializing `vw_lot` if performance benchmarks show it is evaluated too frequently by Wave 2 views. |
| Maintainability | 9.5/10 | Clear column semantics in COMMENT ON VIEW, column alias list, schema-qualified. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.2/10** | Exceeds PROD target (8.0). |

---

## Index Recommendations

| Table | Column(s) | Reason |
|-------|-----------|--------|
| `perseus.material_transition` | `material_id` | Join condition `sl.uid = mt.material_id` |
| `perseus.material_transition` | `transition_id` | Join condition `dl.process_uid = mt.transition_id` |
| `perseus.goo` | `uid` | Supports `vw_lot.uid` join condition (vw_lot.uid = goo.uid) |
| `perseus.fatsmurf` | `uid` | Supports `vw_lot.process_uid` join condition (vw_lot.process_uid = fatsmurf.uid) |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.5 hours |
| Risk | Low |
| Blocker | `perseus.vw_lot` (Wave 0) must be deployed first |

**Effort breakdown:**
- 0.15 h — Schema correction, remove quotes on view name, add OR REPLACE
- 0.15 h — Verify `material_transition.added_on` is TIMESTAMPTZ on DEV
- 0.1 h — Add `COMMENT ON VIEW`, column alias list, format DDL
- 0.1 h — Syntax validation with `psql`, EXPLAIN ANALYZE spot check on DEV

**Deployment prerequisite:** `perseus.vw_lot` (Wave 0, T038) must be created before this Wave 1 view is deployed.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
