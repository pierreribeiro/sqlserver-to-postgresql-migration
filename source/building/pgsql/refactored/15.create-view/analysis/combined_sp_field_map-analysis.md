# Analysis: combined_sp_field_map (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.combined_sp_field_map` |
| PostgreSQL name | `perseus.combined_sp_field_map` |
| Type | Standard View |
| Priority | P3 |
| Complexity | 5/10 |
| Wave | Wave 0 (depends only on base tables) |
| Depends on | `perseus.smurf_property`, `perseus.smurf`, `perseus.property`, `perseus.unit`, `perseus.property_option` (base tables, deployed ✅) |
| Blocks | `perseus.combined_field_map` (Wave 1) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/3.perseus.dbo.combined_sp_field_map.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/3.perseus.combined_sp_field_map.sql` |

---

## Source Query Analysis

This view produces a synthetic "field map" record set derived from `smurf_property` configurations. It generates three distinct record types via UNION, each representing a different UI rendering context for fatsmurf poll value data:

**Branch 1 — Fatsmurf reading editing** (`id = sp.id + 20000`, `field_map_block_id = sp.smurf_id + 1000`, `save_sequence = 1`, has setter):
Represents editable fatsmurf readings in a detail form. The `setter` expression `'setPollValueBySpid(' + sp.id + ', ?)'` generates a JavaScript setter method call. The `lookup` expression generates a `PropertyPeer::getLookupByPropertyId()` PHP method call when the property has an associated option.

**Branch 2 — Fatsmurf list and CSV** (`id = sp.id + 30000`, `field_map_block_id = sp.smurf_id + 2000`, `save_sequence = 2`, no setter, no lookup):
Represents read-only list and CSV display contexts.

**Branch 3 — Fatsmurf single reading editing** (`id = sp.id + 40000`, `field_map_block_id = sp.smurf_id + 3000`, `save_sequence = 2`, has setter):
Represents single-reading edit forms — same setter logic as Branch 1 but with `save_sequence = 2`.

**Key observations:**
- `CONVERT(VARCHAR(50), NULL)` is used throughout to produce typed NULL columns for `description`, `lookup_service`, `database_id`, `onchange`. In PostgreSQL, `NULL::TEXT` or `CAST(NULL AS TEXT)` is equivalent.
- The `[lookup]` column uses SQL Server bracket quoting — `lookup` is not a reserved word in PostgreSQL, so no quoting needed.
- UNION (not UNION ALL) is used — deduplication between branches is intentional (though in practice, the `id` offsets of 20000/30000/40000 ensure no duplicates across branches).
- Each branch joins the same five tables (`smurf_property`, `smurf`, `property`, `unit`, `property_option`) with identical join conditions — no differences in table access, only in the projected expressions.
- Branch 2 second-to-last column in T-SQL has no explicit alias — the column inherits from the CASE expression, which in PostgreSQL will produce an auto-generated name. This should be given an explicit alias `field_map_set_id`.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.combined_sp_field_map` with all table references under `perseus_dbo`. All base tables are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — `WITH SCHEMABINDING` clause must be removed

**Severity:** P2
**Location:** T-SQL original — `CREATE VIEW combined_sp_field_map WITH SCHEMABINDING AS`
**Description:** SQL Server-only clause — not supported in PostgreSQL. AWS SCT correctly strips this.
**Fix:** Remove `WITH SCHEMABINDING`. AWS SCT handles this.

---

#### P2-02 — `+` string concatenation → `||` operator

**Severity:** P2
**Location:** Multiple SELECT list expressions across all three branches
**Description:** T-SQL uses `+` for string concatenation. PostgreSQL uses `||`. Examples:
- `p.name + CASE WHEN u.name IS NOT NULL THEN ' (' + u.name + ')' ELSE '' END`
- `'setPollValueBySpid(' + CONVERT(VARCHAR(25), sp.id) + ', ?)'`
- `'PropertyPeer::getLookupByPropertyId(' + CAST(po.property_id AS VARCHAR(10)) + ')'`

AWS SCT correctly converts all `+` occurrences to `||`. Manual verification is still required.
**Fix:** AWS SCT handles this.

---

#### P2-03 — `CONVERT(VARCHAR(n), expr)` → `expr::TEXT` or `CAST(expr AS VARCHAR(n))`

**Severity:** P2
**Location:** Multiple expressions — `CONVERT(VARCHAR(50), NULL)`, `CONVERT(VARCHAR(25), sp.id)`, `CAST(po.property_id AS VARCHAR(10))`
**Description:**
- `CONVERT(VARCHAR(50), NULL)` → `NULL::TEXT` (typed NULL)
- `CONVERT(VARCHAR(25), sp.id)` → `sp.id::TEXT` (integer to text)
- `CAST(po.property_id AS VARCHAR(10))` — `CAST` syntax is valid in PostgreSQL as-is; can remain or be written as `po.property_id::TEXT`

AWS SCT converts `CONVERT(VARCHAR(n), NULL)` to `CAST(NULL AS VARCHAR(n))` and `CONVERT(VARCHAR(25), sp.id)` to `CAST(sp.id AS VARCHAR(25))`. Both are valid PostgreSQL syntax.
**Fix:** AWS SCT handles this. Prefer `::TEXT` in production DDL for idiomatic PostgreSQL style.

---

#### P2-04 — Missing explicit column alias on CASE expression in Branch 2 and Branch 3

**Severity:** P2
**Location:** Branches 2 and 3 — final CASE expression `CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END` has no alias
**Description:** In the T-SQL original, Branch 1 ends with `CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END AS field_map_set_id`. Branches 2 and 3 omit the `AS field_map_set_id` alias. In a UNION, column names are determined by the first branch, so the column is correctly named in the result set. However, the missing aliases make the code harder to read and maintain. AWS SCT preserves this inconsistency.
**Fix:** Add explicit `AS field_map_set_id` alias to the final CASE expression in Branches 2 and 3 in the production DDL.

---

#### P2-05 — `[lookup]` bracket notation — not a reserved word in PostgreSQL

**Severity:** P2 (informational)
**Location:** `CASE WHEN po.property_id IS NULL THEN NULL ELSE '...' END AS [lookup]`
**Description:** `lookup` uses SQL Server bracket notation. In PostgreSQL, `lookup` is NOT a reserved word (confirmed via `pg_get_keywords()`). No quoting is needed in the production DDL. AWS SCT correctly removes the brackets.
**Fix:** Use bare `lookup` in the production DDL. No quoting required.

---

#### P2-06 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.combined_sp_field_map IS '...'`.

---

#### P2-07 — Orphan comment at end of SCT output

**Severity:** P2 (minor)
**Location:** AWS SCT output — last line: `/* all fatsmurf reading */`
**Description:** SCT moved the first branch's comment to the end of the file (after the semicolon), making it an orphan comment after the DDL statement. Remove in production DDL.
**Fix:** Remove the misplaced comment.

---

### P3 Issues

#### P3-01 — UNION vs UNION ALL — confirm deduplication intent

**Severity:** P3 (design validation)
**Location:** Between all three branches
**Description:** The view uses `UNION` (with deduplication). Because the `id` values in each branch are offset by 20000, 30000, 40000 on top of the base `sp.id`, cross-branch duplicates are structurally impossible (assuming `sp.id` values are unique). Using `UNION ALL` would be slightly more efficient. However, deduplication intent must be confirmed with the business owner before changing `UNION` to `UNION ALL`, as the original may have used `UNION` defensively.
**Note:** Retain `UNION` for fidelity. Flag for future optimization if needed.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `WITH SCHEMABINDING` | Remove | CREATE VIEW header | Not supported in PostgreSQL |
| `+` (string concat) | `\|\|` | All branches, name/setter/lookup expressions | AWS SCT handles this |
| `CONVERT(VARCHAR(50), NULL)` | `NULL::TEXT` | description, lookup_service, database_id, onchange | AWS SCT uses `CAST(NULL AS VARCHAR(50))` — both valid |
| `CONVERT(VARCHAR(25), sp.id)` | `sp.id::TEXT` | setter expression | AWS SCT uses `CAST(sp.id AS VARCHAR(25))` — both valid |
| `CAST(po.property_id AS VARCHAR(10))` | `po.property_id::TEXT` | lookup expression | Already valid ANSI CAST syntax |
| `dbo.smurf_property` | `perseus.smurf_property` | All branches | Schema correction |
| `dbo.smurf` | `perseus.smurf` | All branches | Schema correction |
| `dbo.property` | `perseus.property` | All branches | Schema correction |
| `dbo.unit` | `perseus.unit` | All branches | Schema correction |
| `dbo.property_option` | `perseus.property_option` | All branches | Schema correction |
| `AS [lookup]` | `AS lookup` | All branches | Drop brackets — not reserved in PostgreSQL |
| Missing alias on final CASE | `AS field_map_set_id` | Branches 2 and 3 | Explicit alias for clarity |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.combined_sp_field_map IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`3.perseus.combined_sp_field_map.sql`) key characteristics:
- `WITH SCHEMABINDING` removed — ✅
- `+` converted to `||` — ✅
- `CONVERT(VARCHAR(n), expr)` → `CAST(expr AS VARCHAR(n))` — ✅ (valid PostgreSQL)
- `[lookup]` brackets removed — ✅
- Schema `perseus_dbo` — WRONG (P1-01)
- Missing explicit aliases on Branches 2 and 3 final CASE — preserved from T-SQL (P2-04)
- Orphan comment `/* all fatsmurf reading */` at end — minor (P2-07)
- No `COMMENT ON VIEW` — missing (P2-06)

**SCT reliability score: 7/10**
Syntactic transformations are all correct. Schema name is the only material defect. The missing alias and orphan comment are inherited from the T-SQL source rather than SCT errors.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.combined_sp_field_map
-- Description: Generates synthetic field_map records from smurf_property definitions.
--              Three branches represent different UI rendering contexts:
--              Branch 1 (id+20000, block+1000): Fatsmurf reading edit form (setter=set)
--              Branch 2 (id+30000, block+2000): Fatsmurf list/CSV (no setter, save_seq=2)
--              Branch 3 (id+40000, block+3000): Fatsmurf single reading edit (setter=set)
--              Combined with field_map base table in perseus.combined_field_map (Wave 1).
--
-- Depends on:  perseus.smurf_property (base table ✅)
--              perseus.smurf (base table ✅)
--              perseus.property (base table ✅)
--              perseus.unit (base table ✅)
--              perseus.property_option (base table ✅)
-- Blocks:      perseus.combined_field_map (Wave 1)
-- Wave:        Wave 0
-- T-SQL ref:   dbo.combined_sp_field_map
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_sp_field_map (
    id,
    field_map_block_id,
    name,
    description,
    display_order,
    setter,
    lookup,
    lookup_service,
    nullable,
    field_map_type_id,
    database_id,
    save_sequence,
    onchange,
    field_map_set_id
) AS

-- Branch 1: Fatsmurf reading editing (editable poll values, detail form)
SELECT
    sp.id + 20000                                                      AS id,
    sp.smurf_id + 1000                                                 AS field_map_block_id,
    p.name || CASE WHEN u.name IS NOT NULL
                   THEN ' (' || u.name || ')'
                   ELSE ''
              END                                                       AS name,
    NULL::TEXT                                                         AS description,
    sp.sort_order                                                      AS display_order,
    'setPollValueBySpid(' || sp.id::TEXT || ', ?)'                    AS setter,
    CASE WHEN po.property_id IS NULL THEN NULL
         ELSE 'PropertyPeer::getLookupByPropertyId('
              || po.property_id::TEXT || ')'
    END                                                                AS lookup,
    NULL::TEXT                                                         AS lookup_service,
    1                                                                  AS nullable,
    CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END          AS field_map_type_id,
    NULL::TEXT                                                         AS database_id,
    1                                                                  AS save_sequence,
    NULL::TEXT                                                         AS onchange,
    CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END                      AS field_map_set_id
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON sp.smurf_id = s.id
JOIN perseus.property AS p
    ON sp.property_id = p.id
LEFT JOIN perseus.unit AS u
    ON u.id = p.unit_id
LEFT JOIN perseus.property_option AS po
    ON po.property_id = p.id

UNION

-- Branch 2: Fatsmurf list and CSV (read-only display contexts)
SELECT
    sp.id + 30000                                                      AS id,
    sp.smurf_id + 2000                                                 AS field_map_block_id,
    p.name || CASE WHEN u.name IS NOT NULL
                   THEN ' (' || u.name || ')'
                   ELSE ''
              END                                                       AS name,
    NULL::TEXT                                                         AS description,
    sp.sort_order                                                      AS display_order,
    NULL                                                               AS setter,
    NULL                                                               AS lookup,
    NULL::TEXT                                                         AS lookup_service,
    1                                                                  AS nullable,
    CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END          AS field_map_type_id,
    NULL::TEXT                                                         AS database_id,
    2                                                                  AS save_sequence,
    NULL::TEXT                                                         AS onchange,
    CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END                      AS field_map_set_id
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON sp.smurf_id = s.id
JOIN perseus.property AS p
    ON sp.property_id = p.id
LEFT JOIN perseus.unit AS u
    ON u.id = p.unit_id
LEFT JOIN perseus.property_option AS po
    ON po.property_id = p.id

UNION

-- Branch 3: Fatsmurf single reading editing (editable, individual read form)
SELECT
    sp.id + 40000                                                      AS id,
    sp.smurf_id + 3000                                                 AS field_map_block_id,
    p.name || CASE WHEN u.name IS NOT NULL
                   THEN ' (' || u.name || ')'
                   ELSE ''
              END                                                       AS name,
    NULL::TEXT                                                         AS description,
    sp.sort_order                                                      AS display_order,
    'setPollValueBySpid(' || sp.id::TEXT || ', ?)'                    AS setter,
    CASE WHEN po.property_id IS NULL THEN NULL
         ELSE 'PropertyPeer::getLookupByPropertyId('
              || po.property_id::TEXT || ')'
    END                                                                AS lookup,
    NULL::TEXT                                                         AS lookup_service,
    1                                                                  AS nullable,
    CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END          AS field_map_type_id,
    NULL::TEXT                                                         AS database_id,
    2                                                                  AS save_sequence,
    NULL::TEXT                                                         AS onchange,
    CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END                      AS field_map_set_id
FROM perseus.smurf_property AS sp
JOIN perseus.smurf AS s
    ON sp.smurf_id = s.id
JOIN perseus.property AS p
    ON sp.property_id = p.id
LEFT JOIN perseus.unit AS u
    ON u.id = p.unit_id
LEFT JOIN perseus.property_option AS po
    ON po.property_id = p.id;

-- Documentation
COMMENT ON VIEW perseus.combined_sp_field_map IS
    'Generates synthetic field_map rows from smurf_property for three UI contexts: '
    '(1) reading edit forms (id+20000, save_seq=1 with setter), '
    '(2) list/CSV views (id+30000, save_seq=2, no setter), '
    '(3) single reading edit forms (id+40000, save_seq=2 with setter). '
    'Combined with field_map base table in combined_field_map (Wave 1). '
    'Depends on: smurf_property, smurf, property, unit, property_option. '
    'T-SQL source: dbo.combined_sp_field_map | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9.5/10 | Three-branch UNION with string concatenation. All constructs valid PostgreSQL 17. |
| Logic Preservation | 9/10 | All three business branches preserved. Explicit aliases added to Branches 2 and 3 final CASE — cosmetic improvement, no logic change. `NULL::TEXT` vs `CAST(NULL AS VARCHAR(50))` — semantically identical. |
| Performance | 7/10 | Three identical five-table JOINs executed per UNION (PostgreSQL evaluates each branch). UNION deduplication adds a sort/hash step. On large `smurf_property` tables this could be expensive. Index on `smurf_property.smurf_id`, `smurf_property.property_id`, `property.unit_id`, `property_option.property_id` critical. |
| Maintainability | 8.5/10 | Clear branch comments, explicit aliases on all columns, COMMENT ON VIEW present. The three-branch repetition is inherent in the original design. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. The setter/lookup strings are static concatenations of database integer IDs — no user input injection risk. |
| **Overall** | **8.7/10** | Exceeds PROD target (8.0). |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 1.0 hour |
| Risk | Low |
| Blocker | None (all dependencies are deployed base tables) |

**Effort breakdown:**
- 0.25 h — Schema correction across 15 table references (3 branches × 5 tables)
- 0.25 h — Verify `||` concat, `::TEXT` casts, explicit aliases in Branches 2 and 3
- 0.25 h — Add column alias list to CREATE VIEW header, add COMMENT ON VIEW
- 0.25 h — Syntax validation with `psql` on DEV, EXPLAIN ANALYZE on DEV

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
