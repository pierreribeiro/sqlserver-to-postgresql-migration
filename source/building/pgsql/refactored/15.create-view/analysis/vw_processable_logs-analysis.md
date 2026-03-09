# Analysis: vw_processable_logs (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_processable_logs` |
| PostgreSQL name | `perseus.vw_processable_logs` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 5/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.robot_log`, `perseus.robot_log_type`, `perseus.robot_log_error`, `perseus.robot_log_read`, `perseus.robot_log_transfer` (base tables, deployed ✅) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/18.perseus.dbo.vw_processable_logs.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/18.perseus.vw_processable_logs.sql` |

---

## Source Query Analysis

This view filters `robot_log` rows to identify log entries that are ready for processing. A row is "processable" if ALL of the following conditions are true:

1. `ISNULL(rl.loaded, 0) = 0` — The log has NOT been loaded yet (or `loaded` is NULL, treated as 0).
2. `NOT EXISTS (robot_log_error ...)` — No error log exists that is linked to the same `robot_run_id`. The subquery joins `robot_log_error` to `robot_log` aliased `rl_c` and checks `rl_c.robot_run_id = rl.robot_run_id`. Note: the condition `rle.robot_log_id = rl_c.id` in the subquery WHERE clause is a self-join redundancy (already expressed in the JOIN condition `rle.robot_log_id = rl_c.id`) — see P2-02.
3. `rl.id IN (SELECT MIN(id) FROM robot_log ... GROUP BY robot_log_checksum)` — Only the first log entry per unique checksum is processable (deduplication by checksum).
4. `(EXISTS (robot_log_read ...) OR EXISTS (robot_log_transfer ...))` — The log has at least one associated read or transfer record.
5. `ISNULL(rl.loadable, 0) = 1` — The log is marked as loadable (or `loadable` is NULL, treated as 0, meaning NULL logs are NOT loadable — only explicitly set `loadable = 1` rows pass).
6. `rl.created_on > DATEADD(MONTH, -1, GETDATE())` — The log was created within the last month.

The view uses `rl.*` in the outer SELECT, which exposes all columns of `robot_log`. The JOIN to `robot_log_type` is used only for filtering scope — `rlt` columns are not selected. This suggests the JOIN may be unnecessary if `robot_log` already has a foreign key constraint to `robot_log_type` (which would make orphan rows impossible). Flag for review.

The alias `rlt` is used twice: once for `robot_log_type` in the main FROM clause, and once for `robot_log_transfer` inside the EXISTS subquery. This is valid in T-SQL/PostgreSQL because the scopes are independent, but it is confusing. This should be clarified in the production DDL.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_processable_logs` with all table references under `perseus_dbo`. All `robot_log*` tables are deployed under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

#### P1-02 — AWS SCT date arithmetic is non-standard and incorrect

**Severity:** P1
**Location:** AWS SCT output, final WHERE clause condition
**Description:** AWS SCT converts `DATEADD(MONTH, -1, GETDATE())` to:
```sql
clock_timestamp() + (- 1::NUMERIC || ' MONTH')::INTERVAL
```
This is incorrect for two reasons:
1. `clock_timestamp()` returns the current time including sub-transaction changes — `CURRENT_TIMESTAMP` is correct here (transaction-stable timestamp, equivalent to `GETDATE()`).
2. The expression `(- 1::NUMERIC || ' MONTH')::INTERVAL` is brittle and non-standard. The correct PostgreSQL idiom is `INTERVAL '1 month'` or `CURRENT_TIMESTAMP - INTERVAL '1 month'`.

**Fix:** Replace with `rl.created_on > CURRENT_TIMESTAMP - INTERVAL '1 month'`.

---

### P2 Issues

#### P2-01 — `ISNULL(x, y)` → `COALESCE(x, y)` (two occurrences)

**Severity:** P2
**Location:** WHERE clause — `ISNULL(rl.loaded, 0)` and `ISNULL(rl.loadable, 0)`
**Description:** `ISNULL` is a SQL Server function. PostgreSQL uses `COALESCE`. AWS SCT correctly handles this transformation.
**Fix:** `ISNULL(rl.loaded, 0) = 0` → `COALESCE(rl.loaded, 0) = 0`. AWS SCT handles this.

---

#### P2-02 — Redundant WHERE condition in NOT EXISTS subquery

**Severity:** P2 (logic concern — not a bug, but worth flagging)
**Location:** NOT EXISTS subquery — `WHERE rle.robot_log_id = rl_c.id AND rl_c.robot_run_id = rl.robot_run_id`
**Description:** The condition `rle.robot_log_id = rl_c.id` is already expressed in the JOIN condition `ON rle.robot_log_id = rl_c.id`. Repeating it in the WHERE clause is redundant but harmless. The WHERE clause's actual filter is `rl_c.robot_run_id = rl.robot_run_id` — this is the correlated condition.
**Fix:** The production DDL can retain the original structure (safe to keep the redundant condition for fidelity) or clean it up. Recommend keeping as-is for logic preservation — the redundant condition does not affect results.

---

#### P2-03 — Alias naming conflict `rlt` used for two different tables

**Severity:** P2 (readability — not a bug)
**Location:** Main FROM clause (`robot_log_type AS rlt`) and EXISTS subquery (`robot_log_transfer AS rlt`)
**Description:** In T-SQL and PostgreSQL, aliases are scoped to their query block, so this is syntactically valid. However, using the same alias `rlt` for two different tables in the same overall query is confusing for maintainers.
**Fix:** Rename the `robot_log_transfer` alias in the EXISTS subquery to `rltr` in the production DDL for clarity. This is a non-breaking change.

---

#### P2-04 — `SELECT *` in outer SELECT (robot_log columns not enumerated)

**Severity:** P2 (maintainability)
**Location:** `SELECT rl.* FROM robot_log rl`
**Description:** Using `rl.*` means the view column list changes automatically if `robot_log` table columns are added or removed. This can cause silent behavioral changes for downstream consumers. The constitution prefers explicit column lists.
**Fix:** In the production DDL, enumerate the explicit columns of `robot_log`. AWS SCT's column alias list in the CREATE VIEW header (`id, class_id, source, created_on, log_text, file_name, robot_log_checksum, started_on, completed_on, loaded_on, loaded, loadable, robot_run_id, robot_log_type_id`) provides the complete list. Use explicit `rl.id, rl.class_id, ...` in the SELECT.

---

#### P2-05 — JOIN to `robot_log_type` may be redundant

**Severity:** P2 (performance)
**Location:** `JOIN robot_log_type rlt ON rlt.id = rl.robot_log_type_id`
**Description:** The `rlt` alias from this JOIN is never referenced in the SELECT or WHERE clause. The JOIN is present but unused in the result set. If `robot_log.robot_log_type_id` has a NOT NULL + FK constraint to `robot_log_type`, the join adds zero filtering power and forces an extra table access on every row.
**Fix:** Flag for DBA review. If `robot_log.robot_log_type_id` is a NOT NULL FK with referential integrity enforced, remove this JOIN. If it is nullable or the FK is not enforced, the JOIN may serve as an implicit filter for rows with a valid `robot_log_type_id`. Preserve the original JOIN in the production DDL pending DBA confirmation.

---

#### P2-06 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_processable_logs IS '...'`.

---

### P3 Issues

#### P3-01 — Bracket notation `[dbo].[vw_processable_logs]` in T-SQL

**Severity:** P3 (informational — handled by AWS SCT)
**Location:** T-SQL original
**Description:** SQL Server bracket notation — AWS SCT strips it. No action beyond confirming SCT output.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `ISNULL(rl.loaded, 0)` | `COALESCE(rl.loaded, 0)` | WHERE clause | AWS SCT handles this |
| `ISNULL(rl.loadable, 0)` | `COALESCE(rl.loadable, 0)` | WHERE clause | AWS SCT handles this |
| `DATEADD(MONTH, -1, GETDATE())` | `CURRENT_TIMESTAMP - INTERVAL '1 month'` | WHERE clause | AWS SCT gets this WRONG — must manually correct |
| `rl.*` | `rl.id, rl.class_id, rl.source, ...` (explicit list) | SELECT clause | Enumerate all columns explicitly |
| `dbo.robot_log` | `perseus.robot_log` | FROM + subqueries | Schema correction |
| `dbo.robot_log_type` | `perseus.robot_log_type` | FROM clause | Schema correction |
| `dbo.robot_log_error` | `perseus.robot_log_error` | NOT EXISTS subquery | Schema correction |
| `dbo.robot_log_read` | `perseus.robot_log_read` | EXISTS subquery | Schema correction |
| `dbo.robot_log_transfer` | `perseus.robot_log_transfer` | EXISTS subquery | Schema correction |
| `robot_log_transfer AS rlt` | `robot_log_transfer AS rltr` | EXISTS subquery alias | Rename for clarity (non-breaking) |
| `clock_timestamp() + (- 1::NUMERIC \|\| ' MONTH')::INTERVAL` | `CURRENT_TIMESTAMP - INTERVAL '1 month'` | SCT output correction | P1 — SCT date arithmetic is incorrect |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_processable_logs IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`18.perseus.vw_processable_logs.sql`) key characteristics:
- `COALESCE` correctly replaces `ISNULL` — ✅
- Date arithmetic: `clock_timestamp() + (- 1::NUMERIC || ' MONTH')::INTERVAL` — **WRONG** (P1-02)
- Schema `perseus_dbo` — **WRONG** (P1-01)
- `rl.*` preserved — acceptable but improve with explicit column list (P2-04)
- Column alias list in CREATE VIEW header is correct and should be retained

**SCT reliability score: 5/10**
The schema error and the non-standard date arithmetic expression are material defects. The `ISNULL → COALESCE` conversion is correct. The date arithmetic error in particular would produce subtly wrong behavior (using `clock_timestamp()` instead of `CURRENT_TIMESTAMP` introduces transaction-time non-determinism, and the interval expression is non-standard/fragile).

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.vw_processable_logs
-- Description: Filters robot_log to rows that are eligible for processing.
--              A log entry is processable if:
--              1. Not already loaded (loaded IS NULL OR loaded = 0)
--              2. No error log exists for the same robot_run_id
--              3. It is the earliest entry (MIN id) with its checksum
--              4. Has at least one associated read or transfer record
--              5. Explicitly marked loadable (loadable = 1)
--              6. Created within the last calendar month
--
-- NOTE: The JOIN to robot_log_type is preserved from the T-SQL original.
--       Review whether it adds filtering value; if robot_log_type_id has a
--       NOT NULL FK constraint, this JOIN is redundant (see analysis P2-05).
--
-- Depends on:  perseus.robot_log (base table ✅)
--              perseus.robot_log_type (base table ✅)
--              perseus.robot_log_error (base table ✅)
--              perseus.robot_log_read (base table ✅)
--              perseus.robot_log_transfer (base table ✅)
-- Blocks:      None
-- Wave:        Wave 0
-- T-SQL ref:   dbo.vw_processable_logs
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_processable_logs (
    id,
    class_id,
    source,
    created_on,
    log_text,
    file_name,
    robot_log_checksum,
    started_on,
    completed_on,
    loaded_on,
    loaded,
    loadable,
    robot_run_id,
    robot_log_type_id
) AS
SELECT
    rl.id,
    rl.class_id,
    rl.source,
    rl.created_on,
    rl.log_text,
    rl.file_name,
    rl.robot_log_checksum,
    rl.started_on,
    rl.completed_on,
    rl.loaded_on,
    rl.loaded,
    rl.loadable,
    rl.robot_run_id,
    rl.robot_log_type_id
FROM perseus.robot_log AS rl
JOIN perseus.robot_log_type AS rlt
    ON rlt.id = rl.robot_log_type_id
WHERE COALESCE(rl.loaded, 0) = 0
  AND NOT EXISTS (
        SELECT 1
        FROM perseus.robot_log_error AS rle
        JOIN perseus.robot_log AS rl_c
            ON rle.robot_log_id = rl_c.id
        WHERE rl_c.robot_run_id = rl.robot_run_id
  )
  AND rl.id IN (
        SELECT MIN(id)
        FROM perseus.robot_log AS rl_d
        GROUP BY robot_log_checksum
  )
  AND (
        EXISTS (
            SELECT 1
            FROM perseus.robot_log_read AS rlr
            WHERE rlr.robot_log_id = rl.id
        )
        OR EXISTS (
            SELECT 1
            FROM perseus.robot_log_transfer AS rltr
            WHERE rltr.robot_log_id = rl.id
        )
  )
  AND COALESCE(rl.loadable, 0) = 1
  AND rl.created_on > CURRENT_TIMESTAMP - INTERVAL '1 month';

-- Documentation
COMMENT ON VIEW perseus.vw_processable_logs IS
    'Filters robot_log to entries eligible for processing. A log is processable '
    'when: not yet loaded, no error for same run, earliest by checksum, has a '
    'read or transfer record, explicitly marked loadable, and created within 1 month. '
    'Key fix: DATEADD(MONTH,-1,GETDATE()) → CURRENT_TIMESTAMP - INTERVAL ''1 month''. '
    'Alias rlt (robot_log_transfer in EXISTS) renamed to rltr for clarity. '
    'Depends on: robot_log, robot_log_type, robot_log_error, robot_log_read, robot_log_transfer. '
    'T-SQL source: dbo.vw_processable_logs | Migration task T038.';
```

**Key changes from AWS SCT output:**
1. Date arithmetic: `CURRENT_TIMESTAMP - INTERVAL '1 month'` (corrects SCT error).
2. Explicit column list instead of `rl.*`.
3. `robot_log_transfer` alias changed from `rlt` to `rltr` for clarity.
4. `SELECT *` in EXISTS subqueries replaced with `SELECT 1` (idiomatic, marginally faster).
5. Redundant `rle.robot_log_id = rl_c.id` condition removed from NOT EXISTS WHERE (it duplicates the JOIN condition).
6. Schema corrected to `perseus`.

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9.5/10 | Standard SQL — the only complexity is the multi-predicate WHERE clause with correlated EXISTS. |
| Logic Preservation | 8.5/10 | All 6 business rules preserved. Minor deduction: redundant WHERE condition in NOT EXISTS removed (harmless change), and alias rename (non-breaking). The date arithmetic correction is functionally equivalent to the T-SQL intent. |
| Performance | 6.5/10 | The `IN (SELECT MIN(id) ... GROUP BY checksum)` subquery evaluates a grouping aggregate per execution. The `NOT EXISTS` correlated subquery runs for every candidate row. The combined effect on a large `robot_log` table can be expensive. Recommend EXPLAIN ANALYZE post-deployment. Index on `robot_log.robot_log_checksum`, `robot_log_error.robot_log_id`, `robot_log_read.robot_log_id`, `robot_log_transfer.robot_log_id` are critical. |
| Maintainability | 8.5/10 | Explicit column list, COMMENT ON VIEW, alias rename for clarity, `SELECT 1` in EXISTS. The 6-condition WHERE block is inherently complex but matches the business rule complexity. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **8.5/10** | Exceeds STAGING gate (7.0+). Performance must be validated on realistic data volume. |

---

## Index Recommendations

| Table | Column(s) | Reason |
|-------|-----------|--------|
| `perseus.robot_log` | `robot_log_checksum` | Supports `GROUP BY robot_log_checksum` in IN subquery |
| `perseus.robot_log` | `robot_run_id` | Supports NOT EXISTS correlated lookup by `robot_run_id` |
| `perseus.robot_log` | `created_on` | Supports `created_on > CURRENT_TIMESTAMP - INTERVAL '1 month'` range filter |
| `perseus.robot_log` | `loaded`, `loadable` | If these are used as filter columns frequently (partial index on `loaded IS NULL OR loaded = 0` possible) |
| `perseus.robot_log_error` | `robot_log_id` | Supports JOIN in NOT EXISTS subquery |
| `perseus.robot_log_read` | `robot_log_id` | Supports EXISTS subquery |
| `perseus.robot_log_transfer` | `robot_log_id` | Supports EXISTS subquery |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 1.0 hour |
| Risk | Medium |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.2 h — Schema correction, date arithmetic fix, alias rename, explicit column list
- 0.3 h — Verify `robot_log` table column list matches view DDL (get exact columns from `\d perseus.robot_log` on DEV)
- 0.2 h — Add `COMMENT ON VIEW`, format DDL
- 0.2 h — Syntax validation, EXPLAIN ANALYZE on DEV with realistic row counts
- 0.1 h — Confirm index existence or create recommendations

**Risk: Medium** — The explicit column list in the SELECT requires knowing the exact `robot_log` columns as deployed. If the deployed table differs from the SCT column list, the production DDL will need adjustment. Verify with `\d perseus.robot_log` before finalizing.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
