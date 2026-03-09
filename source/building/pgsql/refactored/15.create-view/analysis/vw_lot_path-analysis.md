# Analysis: vw_lot_path (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_lot_path` |
| PostgreSQL name | `perseus.vw_lot_path` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 3/10 |
| Wave | Wave 1 (depends on `vw_lot`) |
| Depends on | `perseus.m_upstream` (base table ✅), `perseus.vw_lot` (Wave 0 view — must be deployed first) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/15.perseus.dbo.vw_lot_path.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/15.perseus.vw_lot_path.sql` |

---

## Source Query Analysis

This view provides materialized lineage path information between lots, combining the pre-computed upstream path data from `m_upstream` with lot metadata from `vw_lot`.

The `m_upstream` table is populated by the `reconcile_mupstream` stored procedure (stored procedure task — already complete ✅). It contains pre-computed `(start_point, end_point, path, level)` tuples where `start_point` and `end_point` are material UIDs (TEXT — `goo.uid` values).

The view joins `m_upstream` to `vw_lot` twice:
- `sl` (source lot): joins on `sl.uid = mu.end_point` — the lot at the END of the upstream path (i.e., the destination/descendant lot)
- `dl` (destination lot): joins on `dl.uid = mu.start_point` — the lot at the START of the upstream path (i.e., the ancestor/origin lot)

**Note on naming inversion:** Despite the alias names `sl` (source lot) and `dl` (destination lot), the join logic is:
- `sl.uid = mu.end_point` — `sl` is actually the end point of the upstream path (the descendant lot)
- `dl.uid = mu.start_point` — `dl` is actually the start point (the ancestor/origin lot)

This means `src_lot_id` in the output refers to the descendant lot, and `dst_lot_id` refers to the ancestor lot. This naming is inherited from the T-SQL original and must be preserved for backward compatibility.

**Column output:**
- `src_lot_id`: The integer `id` of the lot at the end of the upstream path (descendant)
- `dst_lot_id`: The integer `id` of the lot at the start of the upstream path (ancestor/origin)
- `path`: The upstream path string from `m_upstream` (format: `/uid1/uid2/...`)
- `length`: The path depth from `m_upstream.level`

**Type observations:**
- `mu.end_point` and `mu.start_point` are TEXT (material UIDs — `goo.uid` format)
- `sl.uid` and `dl.uid` from `vw_lot` are TEXT (goo.uid)
- `sl.id` and `dl.id` from `vw_lot` are INTEGER (goo.id)
- `mu.path` is likely VARCHAR(500) in `m_upstream` (per the CHECK constraint documented in `upstream-analysis.md`)
- `mu.level` is INTEGER

The view uses INNER JOINs — only `m_upstream` rows where both the start_point and end_point have corresponding lots in `vw_lot` appear. Paths involving materials not in `goo` (orphaned UIDs) are excluded.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_lot_path` with `FROM perseus_dbo.m_upstream` and references to `perseus_dbo.vw_lot`. Both the base table and Wave 0 view are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — Double-quote identifier quoting in T-SQL original

**Severity:** P2 (informational)
**Location:** T-SQL original — `CREATE VIEW "vw_lot_path" AS`
**Description:** ANSI double-quote quoting in T-SQL. Not needed in PostgreSQL for `vw_lot_path` (lowercase snake_case).
**Fix:** `CREATE OR REPLACE VIEW perseus.vw_lot_path AS` (no quotes).

---

#### P2-02 — Naming inversion in aliases `sl`/`dl` — document business semantics

**Severity:** P2 (documentation concern — not a bug)
**Location:** JOIN aliases and output column names
**Description:** `sl.uid = mu.end_point` means `sl` (alias "source lot") is actually the descendant lot (end of upstream path). `dl.uid = mu.start_point` means `dl` (alias "destination lot") is actually the ancestor lot (start of upstream path). This is a naming inversion inherited from the T-SQL original. Must be documented clearly to prevent future confusion. Do NOT change the output column names (`src_lot_id`, `dst_lot_id`) — breaking change.
**Fix:** Document the inversion in `COMMENT ON VIEW`.

---

#### P2-03 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_lot_path IS '...'`.

---

#### P2-04 — Verify `m_upstream` table columns match expected structure

**Severity:** P2 (pre-deployment validation)
**Location:** `FROM m_upstream mu` — columns `mu.path`, `mu.level`, `mu.end_point`, `mu.start_point`
**Description:** The `m_upstream` table is populated by `reconcile_mupstream`. Verify the column names are exactly `start_point`, `end_point`, `path`, `level` before deployment. Run `\d perseus.m_upstream` on DEV.
**Fix:** Validation query: `SELECT column_name FROM information_schema.columns WHERE table_schema = 'perseus' AND table_name = 'm_upstream';`

---

### P3 Issues

#### P3-01 — Unqualified table names in T-SQL original

**Severity:** P3 (informational)
**Location:** T-SQL original — `FROM m_upstream mu`, `JOIN vw_lot sl`, `JOIN vw_lot dl` — no schema prefix
**Description:** Requires explicit `FROM perseus.m_upstream`, `JOIN perseus.vw_lot` in PostgreSQL. AWS SCT handles this (wrong schema, corrected manually).

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW "vw_lot_path" AS` | `CREATE OR REPLACE VIEW perseus.vw_lot_path AS` | DDL header | Remove quotes, schema prefix, OR REPLACE |
| `FROM m_upstream mu` | `FROM perseus.m_upstream AS mu` | FROM clause | Schema + AS keyword |
| `JOIN vw_lot sl ON sl.uid = mu.end_point` | `JOIN perseus.vw_lot AS sl ON sl.uid = mu.end_point` | First JOIN | Schema + AS keyword |
| `JOIN vw_lot dl ON dl.uid = mu.start_point` | `JOIN perseus.vw_lot AS dl ON dl.uid = mu.start_point` | Second JOIN | Schema + AS keyword |
| `perseus_dbo.*` (SCT output) | `perseus.*` | All references | Schema correction |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_lot_path IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`15.perseus.vw_lot_path.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_lot_path (src_lot_id, dst_lot_id, path, length) AS
SELECT
    sl.id AS src_lot_id, dl.id AS dst_lot_id, mu.path, mu.level AS length
    FROM perseus_dbo.m_upstream AS mu
    JOIN perseus_dbo.vw_lot AS sl
        ON sl.uid = mu.end_point
    JOIN perseus_dbo.vw_lot AS dl
        ON dl.uid = mu.start_point;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added column alias list `(src_lot_id, dst_lot_id, path, length)` in header — correct.
- Removed ANSI double quotes from view name — correct.
- Added `AS` keyword for table aliases — correct.
- Preserved all join conditions faithfully — correct.
- No T-SQL-specific syntax to convert.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.

**SCT reliability score: 8/10**
Cleanest possible SCT output — schema name is the only defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_lot_path
-- Description: Pre-computed lot-to-lot upstream lineage paths. Combines the
--              materialized upstream path data from m_upstream (populated by
--              reconcile_mupstream stored procedure) with lot metadata from vw_lot.
--
--              Column semantics (NOTE: naming inversion from T-SQL original):
--              src_lot_id — goo.id of the DESCENDANT lot (mu.end_point → vw_lot.uid)
--              dst_lot_id — goo.id of the ANCESTOR/ORIGIN lot (mu.start_point → vw_lot.uid)
--              path       — Upstream path string from m_upstream (format: /uid1/uid2/...)
--              length     — Path depth (number of hops) from m_upstream.level
--
--              Despite the alias names sl (source lot) and dl (destination lot):
--              - sl joins on end_point   → sl is actually the DESCENDANT lot
--              - dl joins on start_point → dl is actually the ANCESTOR lot
--              Column names are preserved from the T-SQL original for compatibility.
--
--              INNER JOIN: only m_upstream rows where both start_point and end_point
--              correspond to existing goo records appear in the result.
--
-- Depends on:  perseus.m_upstream (base table — populated by reconcile_mupstream ✅)
--              perseus.vw_lot (Wave 0 view — must be deployed first)
-- Blocks:      None
-- Wave:        Wave 1
-- T-SQL ref:   dbo.vw_lot_path
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_lot_path (
    src_lot_id,
    dst_lot_id,
    path,
    length
) AS
SELECT
    sl.id          AS src_lot_id,
    dl.id          AS dst_lot_id,
    mu.path,
    mu.level       AS length
FROM perseus.m_upstream AS mu
JOIN perseus.vw_lot AS sl
    ON sl.uid = mu.end_point
JOIN perseus.vw_lot AS dl
    ON dl.uid = mu.start_point;

-- Documentation
COMMENT ON VIEW perseus.vw_lot_path IS
    'Pre-computed lot-to-lot upstream lineage paths from m_upstream. '
    'NOTE naming inversion (inherited from T-SQL): src_lot_id is the DESCENDANT lot '
    '(mu.end_point), dst_lot_id is the ANCESTOR lot (mu.start_point). '
    'path: upstream path string (/uid1/uid2/...). '
    'length: hop count. '
    'INNER JOIN: excludes m_upstream rows where start_point or end_point have no goo record. '
    'Depends on: m_upstream (base table, populated by reconcile_mupstream), vw_lot (Wave 0). '
    'T-SQL source: dbo.vw_lot_path | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Three-table INNER JOIN — minimal complexity. |
| Logic Preservation | 9/10 | All join conditions preserved. Naming inversion documented (not corrected — backward compat). Minor deduction for the documented naming inversion which is a latent confusion risk. |
| Performance | 8.5/10 | `m_upstream` is a pre-computed materialized table (populated by `reconcile_mupstream`) — reads from this table are index-accessible if `start_point` and `end_point` are indexed. Double self-join on `vw_lot` (same cost concern as `vw_lot_edge`). Index on `m_upstream.end_point` and `m_upstream.start_point` are critical. |
| Maintainability | 9/10 | Naming inversion documented in COMMENT ON VIEW, column alias list, schema-qualified. The join logic is clean. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.2/10** | Exceeds PROD target (8.0). |

---

## Index Recommendations

| Table | Column(s) | Reason |
|-------|-----------|--------|
| `perseus.m_upstream` | `end_point` | Join condition `sl.uid = mu.end_point` |
| `perseus.m_upstream` | `start_point` | Join condition `dl.uid = mu.start_point` |
| `perseus.goo` | `uid` | Supports `vw_lot.uid` joins (both sl and dl paths) |

Verify these indexes with `\d perseus.m_upstream` before deployment.

---

## Pre-Deployment Validation Query

```sql
-- Verify m_upstream has the expected columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'perseus' AND table_name = 'm_upstream'
ORDER BY ordinal_position;
-- Expected: start_point (text/varchar), end_point (text/varchar), path (text/varchar), level (integer)

-- Spot check: m_upstream should have data if reconcile_mupstream has run
SELECT COUNT(*) FROM perseus.m_upstream;
```

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | `perseus.vw_lot` (Wave 0) must be deployed first. `m_upstream` must be populated by `reconcile_mupstream`. |

**Effort breakdown:**
- 0.1 h — Schema correction, remove quotes on view name, add OR REPLACE
- 0.1 h — Add `COMMENT ON VIEW` with naming inversion documentation, column alias list, format DDL
- 0.05 h — Syntax validation with `psql`, run pre-deployment validation queries on DEV

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
