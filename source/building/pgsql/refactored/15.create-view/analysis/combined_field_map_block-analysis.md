# Analysis: combined_field_map_block (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.combined_field_map_block` |
| PostgreSQL name | `perseus.combined_field_map_block` |
| Type | Standard View |
| Priority | P3 |
| Complexity | 4/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.field_map_block`, `perseus.smurf` (base tables, deployed ✅) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/1.perseus.dbo.combined_field_map_block.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/1.perseus.combined_field_map_block.sql` |

---

## Source Query Analysis

This view generates a unified `field_map_block` record set from two sources: the base `field_map_block` table and synthetic records derived from `smurf` entries. The four-branch UNION creates three synthetic block types from the `smurf` table:

**Branch 1 — Base blocks:** `SELECT id, filter, scope FROM field_map_block` — passes through the real `field_map_block` records unchanged.

**Branch 2 — FatSmurf Readings** (`id = smurf.id + 1000`): Generates a "reading" block for each smurf. The `filter` value `'isSmurf(N)'` is a PHP method call string used by the application to evaluate whether a UI context matches this smurf. The `scope` is `'FatSmurfReading'`.

**Branch 3 — FatSmurf List/CSV** (`id = smurf.id + 2000`): Similar to Branch 2 but `scope = 'FatSmurf'` — for list and CSV display contexts.

**Branch 4 — Single Reading FatSmurf** (`id = smurf.id + 3000`): Uses `'isSmurfWithOneReading(N)'` filter for smurfs that have only one reading. `scope = 'FatSmurf'`.

**Key observations:**
- The `id` offsets (+1000, +2000, +3000) ensure no overlap with the base `field_map_block` table IDs — assuming base `field_map_block.id` values are below 1000 (verify on DEV).
- `CONVERT(VARCHAR(10), id)` converts `smurf.id` (integer) to a string for concatenation into the filter/PHP call string. AWS SCT handles this.
- UNION (not UNION ALL) — deduplication is applied between branches. Cross-branch duplicates are structurally impossible due to `id` offsets and different `scope`/`filter` values. `UNION ALL` would be more efficient but is a behavioral change. Retain `UNION` for fidelity.
- The view does NOT have `WITH SCHEMABINDING` in the T-SQL original — unlike `combined_sp_field_map` and `combined_sp_field_map_display_type`. This simplifies conversion.
- The view does NOT reference `dbo.` in the T-SQL original for `field_map_block` and `smurf` — uses bare table names. Schema qualification is still required in PostgreSQL.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.combined_field_map_block` with `FROM perseus_dbo.field_map_block` and `FROM perseus_dbo.smurf`. Both tables are deployed under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — `+` string concatenation → `||` operator

**Severity:** P2
**Location:** All branches (2, 3, 4) — filter column: `'isSmurf(' + CONVERT(VARCHAR(10), id) + ')'`
**Description:** T-SQL uses `+` for string concatenation. PostgreSQL uses `||`. AWS SCT correctly converts all occurrences.
**Fix:** AWS SCT handles this.

---

#### P2-02 — `CONVERT(VARCHAR(10), id)` → `id::TEXT`

**Severity:** P2
**Location:** Branches 2, 3, 4 — filter column expression
**Description:** `CONVERT` is SQL Server-only. AWS SCT converts to `CAST(id AS VARCHAR(10))` which is valid PostgreSQL. Production DDL uses `id::TEXT` (idiomatic PostgreSQL).
**Fix:** AWS SCT handles this. Use `id::TEXT` in production DDL.

---

#### P2-03 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.combined_field_map_block IS '...'`.

---

#### P2-04 — Verify `field_map_block.id` values do not exceed 999

**Severity:** P2 (pre-deployment validation)
**Location:** ID offset design assumption
**Description:** Branch 2 uses `smurf.id + 1000` as the composite ID. If any `field_map_block.id` value is >= 1000, there could be a collision with the synthetic IDs from Branch 2 (smurf with id=1 would produce id=1001, clashing with a field_map_block.id=1001). Verify on DEV before deployment.
**Fix:** Run `SELECT MAX(id) FROM perseus.field_map_block;` — must be < 1000. Also run `SELECT COUNT(*) FROM perseus.smurf WHERE id > 1000000 - 1000;` to ensure no smurf overflow into reserved ID space.

---

### P3 Issues

#### P3-01 — Unqualified table names in T-SQL original

**Severity:** P3 (informational — schema qualification required in PostgreSQL)
**Location:** T-SQL original — `FROM field_map_block`, `FROM smurf` (no schema prefix)
**Description:** The T-SQL original uses unqualified names. The database context (`USE [perseus]`) resolves them. In PostgreSQL, explicit schema qualification `FROM perseus.field_map_block` is required per Constitution Article VII.
**Fix:** Qualify all references with `perseus.` in the production DDL.

---

#### P3-02 — Branch comments in T-SQL are inline (not block comments)

**Severity:** P3 (style only)
**Location:** T-SQL original — `-- All FatSmurf Readings`, `-- Fields for fatsmurf list and csv`, `-- for single reading fatsmurf editing`
**Description:** AWS SCT converts these to block comments `/* ... */`. Production DDL retains the comments with `--` style for consistency.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `+` (string concat) | `\|\|` | Branches 2, 3, 4 — filter expression | AWS SCT handles this |
| `CONVERT(VARCHAR(10), id)` | `id::TEXT` | Branches 2, 3, 4 | AWS SCT uses CAST — both valid |
| `FROM field_map_block` (unqualified) | `FROM perseus.field_map_block` | Branch 1 | Explicit schema |
| `FROM smurf` (unqualified) | `FROM perseus.smurf` | Branches 2, 3, 4 | Explicit schema |
| `CREATE VIEW combined_field_map_block AS` | `CREATE OR REPLACE VIEW perseus.combined_field_map_block AS` | DDL header | Schema prefix + OR REPLACE |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.combined_field_map_block IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`1.perseus.combined_field_map_block.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.combined_field_map_block (id, filter, scope) AS
SELECT
    id, filter, scope
    FROM perseus_dbo.field_map_block
UNION
/* All FatSmurf Readings */
SELECT
    id + 1000, 'isSmurf(' || CAST (id AS VARCHAR(10)) || ')', 'FatSmurfReading'
    FROM perseus_dbo.smurf
UNION
/* Fields for fatsmurf list and csv */
SELECT
    id + 2000, 'isSmurf(' || CAST (id AS VARCHAR(10)) || ')', 'FatSmurf'
    FROM perseus_dbo.smurf
UNION
/* for single reading fatsmurf editing */
SELECT
    id + 3000, 'isSmurfWithOneReading(' || CAST (id AS VARCHAR(10)) || ')', 'FatSmurf'
    FROM perseus_dbo.smurf;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added column alias list `(id, filter, scope)` in header — correct.
- `+` converted to `||` — correct.
- `CONVERT(VARCHAR(10), id)` → `CAST(id AS VARCHAR(10))` — valid PostgreSQL.
- Preserved all four UNION branches — correct.
- Preserved comments — correct.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.
3. `filter` is used as a column name — verify this is not a reserved word in PostgreSQL (it is not reserved, but check with `pg_get_keywords()`).

**SCT reliability score: 7/10**
Clean conversion — schema name is the only material defect. No structural issues.

**Note on `filter` column name:** `filter` is not a PostgreSQL reserved word per `pg_get_keywords()`. It does not require quoting. Verified acceptable.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.combined_field_map_block
-- Description: Unified field_map_block record set combining the base field_map_block
--              table with three synthetic block types generated from smurf definitions.
--              Four branches via UNION:
--              Branch 1: Real field_map_block rows (id, filter, scope as-is)
--              Branch 2 (id+1000): FatSmurfReading blocks — isSmurf(N) filter
--              Branch 3 (id+2000): FatSmurf list/CSV — isSmurf(N) filter
--              Branch 4 (id+3000): Single-reading FatSmurf — isSmurfWithOneReading(N)
--
--              ASSUMPTION: field_map_block.id < 1000 (no ID collision with Branch 2).
--              Verify with: SELECT MAX(id) FROM perseus.field_map_block;
--
-- Depends on:  perseus.field_map_block (base table ✅)
--              perseus.smurf (base table ✅)
-- Blocks:      None
-- Wave:        Wave 0
-- T-SQL ref:   dbo.combined_field_map_block
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_field_map_block (
    id,
    filter,
    scope
) AS

-- Branch 1: Base field_map_block records
SELECT
    id,
    filter,
    scope
FROM perseus.field_map_block

UNION

-- Branch 2: FatSmurf reading blocks (one per smurf)
SELECT
    id + 1000,
    'isSmurf(' || id::TEXT || ')',
    'FatSmurfReading'
FROM perseus.smurf

UNION

-- Branch 3: FatSmurf list and CSV blocks
SELECT
    id + 2000,
    'isSmurf(' || id::TEXT || ')',
    'FatSmurf'
FROM perseus.smurf

UNION

-- Branch 4: Single-reading FatSmurf blocks
SELECT
    id + 3000,
    'isSmurfWithOneReading(' || id::TEXT || ')',
    'FatSmurf'
FROM perseus.smurf;

-- Documentation
COMMENT ON VIEW perseus.combined_field_map_block IS
    'Unified field map block registry. Combines real field_map_block rows with '
    'three synthetic block types derived from smurf definitions. '
    'Synthetic IDs use offsets +1000 (reading), +2000 (list/csv), +3000 (single read) '
    'to avoid collision with base field_map_block IDs (assumed < 1000). '
    'filter and scope columns drive UI context evaluation in the application layer. '
    'Depends on: field_map_block, smurf (base tables). '
    'T-SQL source: dbo.combined_field_map_block | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Four-branch UNION of simple SELECT statements. No complex constructs. |
| Logic Preservation | 9.5/10 | All branches preserved. `id::TEXT` equivalent to `CAST(id AS VARCHAR(10))`. UNION semantics preserved. |
| Performance | 8/10 | Two-table UNION (smurf appears 3 times). The `field_map_block` and `smurf` tables are likely small — performance is not a concern. The UNION deduplication adds a sort step but on small tables this is negligible. |
| Maintainability | 9/10 | Clear branch comments, column alias list, COMMENT ON VIEW present. Simple structure. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no user-input injection risk. |
| **Overall** | **9.2/10** | Exceeds PROD target (8.0). Near-trivial conversion. |

---

## Pre-Deployment Validation Query

```sql
-- Verify no ID collision between base field_map_block and synthetic IDs
SELECT MAX(id) AS max_base_id FROM perseus.field_map_block;
-- Must be < 1000.

-- Verify smurf table is not empty (branches 2-4 would return 0 rows)
SELECT COUNT(*) AS smurf_count FROM perseus.smurf;
-- Should match SQL Server row count.
```

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.1 h — Schema correction (2 table references), `id::TEXT` idiom, add OR REPLACE
- 0.1 h — Add `COMMENT ON VIEW`, column alias list in header, format DDL
- 0.05 h — Syntax validation with `psql`, run pre-deployment validation queries on DEV

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
