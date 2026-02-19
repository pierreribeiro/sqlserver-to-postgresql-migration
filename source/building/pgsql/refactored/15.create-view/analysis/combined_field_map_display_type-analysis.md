# Analysis: combined_field_map_display_type (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.combined_field_map_display_type` |
| PostgreSQL name | `perseus.combined_field_map_display_type` |
| Type | Standard View |
| Priority | P3 |
| Complexity | 3/10 |
| Wave | Wave 1 (depends on `combined_sp_field_map_display_type`) |
| Depends on | `perseus.field_map_display_type` (base table ✅), `perseus.combined_sp_field_map_display_type` (Wave 0 view) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/2.perseus.dbo.combined_field_map_display_type.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/2.perseus.combined_field_map_display_type.sql` |

---

## Source Query Analysis

This view mirrors the structure of `combined_field_map` but for the display type dimension. It is a two-branch UNION:

**Branch 1:** Selects 6 explicit columns from the base `field_map_display_type` table using T-SQL bracket notation (`[id]`, `[field_map_id]`, `[display_type_id]`, `[display]`, `[display_layout_id]`, plus `manditory` without brackets — note the intentional misspelling).

**Branch 2:** `SELECT * FROM combined_sp_field_map_display_type` — selects all columns from the Wave 0 view using a wildcard.

The combined result set presents a unified display type mapping for all field map entries, whether real (from `field_map_display_type`) or synthetic (from `combined_sp_field_map_display_type` derived from `smurf_property`).

**Key observations:**
- Branch 1 column list: `[id]`, `[field_map_id]`, `[display_type_id]`, `[display]`, `[display_layout_id]`, `manditory` — 6 columns total. The brackets on the first five columns are SQL Server syntax; `manditory` (misspelling) has no brackets.
- `manditory` is an intentional misspelling of "mandatory" present in the original schema and application code. It MUST be preserved.
- `SELECT *` in Branch 2 relies on `combined_sp_field_map_display_type` exposing exactly 6 columns matching Branch 1. The CREATE VIEW header of that view confirms this: `(id, field_map_id, display_type_id, display, display_layout_id, manditory)`.
- UNION (not UNION ALL) — deduplication applied. Cross-branch duplicates are impossible due to ID range separation (base IDs vs synthetic IDs with offsets 10000+–50000+).
- The T-SQL original references `dbo.field_map_display_type` — requires schema qualification in PostgreSQL.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.combined_field_map_display_type` with `FROM perseus_dbo.field_map_display_type` and `FROM perseus_dbo.combined_sp_field_map_display_type`. Both the base table and the Wave 0 view are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — T-SQL bracket notation in Branch 1 SELECT list

**Severity:** P2
**Location:** Branch 1 — `[id]`, `[field_map_id]`, `[display_type_id]`, `[display]`, `[display_layout_id]`
**Description:** SQL Server bracket notation — not valid in PostgreSQL. None of these column names are reserved words in PostgreSQL. AWS SCT correctly removes the brackets.
**Fix:** Remove brackets. AWS SCT handles this.

---

#### P2-02 — `SELECT *` from `combined_sp_field_map_display_type` in Branch 2 — prefer explicit list

**Severity:** P2 (maintainability)
**Location:** Branch 2 — `SELECT * FROM combined_sp_field_map_display_type`
**Description:** Wildcard coupling to the upstream view's column structure. If `combined_sp_field_map_display_type` column count changes, this UNION will fail silently or with a type mismatch error.
**Fix:** Replace `SELECT *` with explicit 6-column list. AWS SCT retains the wildcard — must be manually corrected.

---

#### P2-03 — `manditory` column name — intentional misspelling, must be preserved

**Severity:** P2 (awareness — not a bug to fix)
**Location:** All branches — `manditory` column
**Description:** Misspelling of "mandatory" from the original schema. Retained in the base table and all views for application compatibility. Do NOT correct to `mandatory`.
**Fix:** Preserve `manditory` spelling in all column references.

---

#### P2-04 — `dbo.field_map_display_type` reference without schema in T-SQL original

**Severity:** P2 (informational)
**Location:** T-SQL original — `FROM dbo.field_map_display_type`
**Description:** Uses `dbo.` prefix — must be changed to `perseus.` in PostgreSQL.
**Fix:** `FROM perseus.field_map_display_type`. AWS SCT handles this (wrong schema, corrected manually).

---

#### P2-05 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.combined_field_map_display_type IS '...'`.

---

### P3 Issues

#### P3-01 — `combined_sp_field_map_display_type` reference unqualified in T-SQL original

**Severity:** P3 (informational)
**Location:** T-SQL original — `SELECT * FROM combined_sp_field_map_display_type` (no schema)
**Description:** Requires `FROM perseus.combined_sp_field_map_display_type` in PostgreSQL.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `[id]`, `[field_map_id]`, ... | `id`, `field_map_id`, ... | Branch 1 SELECT | Remove brackets — AWS SCT handles this |
| `FROM dbo.field_map_display_type` | `FROM perseus.field_map_display_type` | Branch 1 FROM | Schema correction |
| `SELECT * FROM combined_sp_field_map_display_type` | Explicit 6-column SELECT from `perseus.combined_sp_field_map_display_type` | Branch 2 | Manual correction |
| `CREATE VIEW combined_field_map_display_type AS` | `CREATE OR REPLACE VIEW perseus.combined_field_map_display_type AS` | DDL header | Schema prefix + OR REPLACE |
| `perseus_dbo.*` (SCT output) | `perseus.*` | All references | Schema correction |
| `manditory` | `manditory` | All branches | Preserve intentional misspelling |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.combined_field_map_display_type IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`2.perseus.combined_field_map_display_type.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.combined_field_map_display_type (id, field_map_id, display_type_id, display, display_layout_id, manditory) AS
/* Display View */
SELECT
    id, field_map_id, display_type_id, display, display_layout_id, manditory
    FROM perseus_dbo.field_map_display_type
UNION
SELECT
    *
    FROM perseus_dbo.combined_sp_field_map_display_type;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added full column alias list in header — correct.
- Removed bracket notation from Branch 1 column list — correct.
- Preserved `manditory` misspelling — correct.
- Preserved `SELECT *` from Branch 2 (same as T-SQL — maintainability concern only).
- Preserved `/* Display View */` comment.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. Retained `SELECT *` in Branch 2 — maintainability concern (P2-02).
3. No `COMMENT ON VIEW` statement.

**SCT reliability score: 7/10**
Schema name is the only material defect. Mirrors the same assessment as `combined_field_map`.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.combined_field_map_display_type
-- Description: Unified field map display type record set. Combines the static
--              field_map_display_type base table with synthetic display type entries
--              from combined_sp_field_map_display_type (five UI contexts derived
--              from smurf_property definitions via combined_sp_field_map_display_type).
--
--              Column descriptions:
--              id                — Composite ID (base: real; synthetic: sp+10000..50000+dl.id)
--              field_map_id      — Links to combined_field_map
--              display_type_id   — Display type identifier (= dl.id from display_layout)
--              display           — PHP method call string for rendering the value
--              display_layout_id — Layout template (5=edit form, 7=table/list/csv)
--              manditory         — 0 (intentional misspelling from original schema)
--
-- NOTE: 'manditory' column name is an intentional misspelling preserved from
--       the original schema for backward application compatibility.
--
-- Depends on:  perseus.field_map_display_type (base table ✅)
--              perseus.combined_sp_field_map_display_type (Wave 0 view — must deploy first)
-- Blocks:      None
-- Wave:        Wave 1
-- T-SQL ref:   dbo.combined_field_map_display_type
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_field_map_display_type (
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
) AS

-- Branch 1: Real field_map_display_type records from base table
SELECT
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
FROM perseus.field_map_display_type

UNION

-- Branch 2: Synthetic display type records from smurf_property definitions
SELECT
    id,
    field_map_id,
    display_type_id,
    display,
    display_layout_id,
    manditory
FROM perseus.combined_sp_field_map_display_type;

-- Documentation
COMMENT ON VIEW perseus.combined_field_map_display_type IS
    'Unified field map display type registry. Combines static field_map_display_type records '
    'with synthetic entries from combined_sp_field_map_display_type (five smurf_property '
    'display contexts: read edit, read table, listing, CSV, single read edit). '
    'Column ''manditory'' (intentional misspelling) preserved for application compatibility. '
    'Wave 1: requires combined_sp_field_map_display_type (Wave 0) to be deployed first. '
    'Depends on: field_map_display_type (base table), combined_sp_field_map_display_type (view). '
    'T-SQL source: dbo.combined_field_map_display_type | Migration task T038.';
```

**Key change from AWS SCT output:**
- Branch 2 `SELECT *` replaced with explicit 6-column list (P2-02 fix).

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Two-branch UNION of 6-column SELECT statements. No complex constructs. |
| Logic Preservation | 9.5/10 | Both branches preserved. Explicit column list in Branch 2 replaces `SELECT *`. `manditory` misspelling preserved correctly. |
| Performance | 8/10 | Branch 1 is a full scan of `field_map_display_type`. Branch 2 evaluates the full `combined_sp_field_map_display_type` view (5-branch UNION). UNION deduplication adds a sort step. Acceptable for typical data sizes. |
| Maintainability | 9.5/10 | Explicit 6-column list in both branches, COMMENT ON VIEW with `manditory` documentation, schema-qualified. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.3/10** | Exceeds PROD target (8.0). |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | `perseus.combined_sp_field_map_display_type` (Wave 0) must be deployed first |

**Effort breakdown:**
- 0.1 h — Schema correction, replace `SELECT *` with explicit column list in Branch 2
- 0.1 h — Add `COMMENT ON VIEW`, column alias list in header, format DDL
- 0.05 h — Syntax validation with `psql` on DEV

**Deployment prerequisite:** `perseus.combined_sp_field_map_display_type` (Wave 0, T038) must be created before this Wave 1 view is deployed.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
