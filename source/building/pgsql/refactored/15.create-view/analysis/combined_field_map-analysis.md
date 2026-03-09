# Analysis: combined_field_map (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.combined_field_map` |
| PostgreSQL name | `perseus.combined_field_map` |
| Type | Standard View |
| Priority | P3 |
| Complexity | 3/10 |
| Wave | Wave 1 (depends on `combined_sp_field_map`) |
| Depends on | `perseus.field_map` (base table ✅), `perseus.combined_sp_field_map` (Wave 0 view) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/0.perseus.dbo.combined_field_map.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/0.perseus.combined_field_map.sql` |

---

## Source Query Analysis

This is a straightforward two-branch UNION view:

**Branch 1:** Selects 14 explicit columns from the base `field_map` table using T-SQL bracket notation (`[id]`, `[field_map_block_id]`, etc.).

**Branch 2:** `SELECT * FROM combined_sp_field_map` — selects all columns from the Wave 0 view using a wildcard.

The combined result set presents a unified interface for all field map records, whether they originate from the static `field_map` table or are generated dynamically by `combined_sp_field_map` from `smurf_property` definitions.

**Key design observations:**
- Branch 1 uses an explicit column list (14 named columns). Branch 2 uses `SELECT *`. In a UNION, column types and names are driven by Branch 1. The `SELECT *` from `combined_sp_field_map` relies on that view having the identical 14-column structure (which it does, per the column alias list in its CREATE VIEW header). The wildcard is safe here but reduces maintainability clarity.
- The 14 columns include `field_map_set_id` (the last column, explicitly named in Branch 1). Branch 2 inherits this name from Branch 1 due to UNION semantics.
- `[lookup]` in Branch 1 uses bracket notation — `lookup` is not a reserved word in PostgreSQL, no quoting needed.
- UNION (not UNION ALL) — deduplication is applied. Cross-branch duplicates are impossible because `field_map.id` values and `combined_sp_field_map.id` values (offsets 20000+, 30000+, 40000+) occupy different ID ranges. `UNION ALL` would be marginally more efficient, but retain `UNION` for fidelity.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and table/view references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.combined_field_map` with `FROM perseus_dbo.field_map` and `FROM perseus_dbo.combined_sp_field_map`. Both the `field_map` table and the `combined_sp_field_map` view are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — T-SQL bracket notation `[column_name]` in Branch 1 SELECT list

**Severity:** P2
**Location:** Branch 1 — `SELECT [id], [field_map_block_id], [name], [description], [display_order], [setter], [lookup], [lookup_service], [nullable], [field_map_type_id], [database_id], [save_sequence], [onchange], field_map_set_id FROM field_map`
**Description:** SQL Server bracket notation is used for all column names except `field_map_set_id` (which has no brackets). PostgreSQL does not use bracket notation. None of these column names are PostgreSQL reserved words, so no quoting is needed.
**Fix:** Remove all `[` and `]` brackets in the production DDL. AWS SCT handles this.

---

#### P2-02 — `SELECT *` from `combined_sp_field_map` in Branch 2 — prefer explicit column list

**Severity:** P2 (maintainability)
**Location:** Branch 2 — `SELECT * FROM combined_sp_field_map`
**Description:** `SELECT *` in a UNION branch couples this view to the column structure of `combined_sp_field_map`. If that view ever gains or loses a column, this UNION will break at creation time (column count mismatch). An explicit column list is safer and more maintainable.
**Fix:** Replace `SELECT *` with the explicit 14-column list matching Branch 1. AWS SCT retains `SELECT *` — this must be manually corrected in production DDL.

---

#### P2-03 — `FROM dbo.field_map_display_type` reference in T-SQL — verify correct table

**Severity:** P2 (verification)
**Location:** Not in this view — clarification only
**Description:** The `combined_field_map` view references `field_map` (Branch 1), not `field_map_display_type`. Confirm that `field_map` is a distinct base table from `field_map_display_type`. Both tables exist in the schema (`field_map` stores the field definitions; `field_map_display_type` stores the display type mappings). This is correct — no issue.

---

#### P2-04 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.combined_field_map IS '...'`.

---

### P3 Issues

#### P3-01 — The `field_map` table reference in Branch 1 has no schema prefix in T-SQL

**Severity:** P3 (informational)
**Location:** T-SQL original — `FROM field_map` (unqualified in the USE [perseus] context)
**Description:** PostgreSQL requires explicit `FROM perseus.field_map`. AWS SCT correctly qualifies to `FROM perseus_dbo.field_map` (wrong schema) — after schema correction this becomes `FROM perseus.field_map`.

---

#### P3-02 — `combined_sp_field_map` reference in Branch 2 has no schema prefix in T-SQL

**Severity:** P3 (informational — same as above)
**Location:** T-SQL original — `SELECT * FROM combined_sp_field_map` (unqualified)
**Description:** Must be qualified as `FROM perseus.combined_sp_field_map` in PostgreSQL.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `[id]`, `[field_map_block_id]`, ... | `id`, `field_map_block_id`, ... | Branch 1 SELECT list | Remove bracket notation — AWS SCT handles this |
| `[lookup]` | `lookup` | Branch 1 SELECT list | Not a reserved word — no quoting needed |
| `FROM field_map` (unqualified) | `FROM perseus.field_map` | Branch 1 FROM | Explicit schema |
| `SELECT * FROM combined_sp_field_map` | Explicit 14-column SELECT from `perseus.combined_sp_field_map` | Branch 2 | Manual correction — AWS SCT retains wildcard |
| `CREATE VIEW combined_field_map AS` | `CREATE OR REPLACE VIEW perseus.combined_field_map AS` | DDL header | Schema prefix + OR REPLACE |
| `perseus_dbo.field_map` | `perseus.field_map` | Branch 1 | Schema correction in SCT output |
| `perseus_dbo.combined_sp_field_map` | `perseus.combined_sp_field_map` | Branch 2 | Schema correction in SCT output |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.combined_field_map IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`0.perseus.combined_field_map.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.combined_field_map (id, field_map_block_id, name, description, display_order, setter, lookup, lookup_service, nullable, field_map_type_id, database_id, save_sequence, onchange, field_map_set_id) AS
/* Field Views */
SELECT
    id, field_map_block_id, name, description, display_order, setter, lookup, lookup_service, nullable, field_map_type_id, database_id, save_sequence, onchange, field_map_set_id
    FROM perseus_dbo.field_map
UNION
SELECT
    *
    FROM perseus_dbo.combined_sp_field_map;
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added full column alias list in header (all 14 columns) — correct.
- Removed bracket notation from Branch 1 column list — correct.
- Preserved `SELECT *` from Branch 2 (same as T-SQL, but see P2-02).
- Preserved the `-- Field Views` comment (converted to `/* Field Views */`).
- Explicit column list in Branch 1 matches the header alias list.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. Retained `SELECT *` in Branch 2 — should be explicit column list (P2-02).
3. No `COMMENT ON VIEW` statement.

**SCT reliability score: 7/10**
Schema name is the only material defect. The `SELECT *` retention is a maintainability concern, not a runtime error.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.combined_field_map
-- Description: Unified field map record set. Combines the static field_map base
--              table with synthetic field map entries generated by combined_sp_field_map
--              (derived from smurf_property definitions for three UI contexts).
--
--              Column descriptions:
--              id              — Unique identifier (base: real ID; synthetic: ID+20000/30000/40000)
--              field_map_block_id — Block grouping (base: real; synthetic: smurf_id+1000/2000/3000)
--              setter          — JavaScript setter method call (NULL for list/CSV context)
--              lookup          — PHP lookup method call (NULL when no property_option)
--              save_sequence   — Ordering within a field map block (1 or 2)
--              field_map_set_id — UI set grouping (9 for smurf class_id=2, 12 otherwise)
--
-- Depends on:  perseus.field_map (base table ✅)
--              perseus.combined_sp_field_map (Wave 0 view — must be deployed first)
-- Blocks:      None
-- Wave:        Wave 1
-- T-SQL ref:   dbo.combined_field_map
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.combined_field_map (
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

-- Branch 1: Real field_map records from base table
SELECT
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
FROM perseus.field_map

UNION

-- Branch 2: Synthetic field_map records from smurf_property definitions
SELECT
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
FROM perseus.combined_sp_field_map;

-- Documentation
COMMENT ON VIEW perseus.combined_field_map IS
    'Unified field map registry. Combines static field_map records with synthetic '
    'entries from combined_sp_field_map (derived from smurf_property for three UI contexts). '
    'Synthetic IDs use offsets +20000, +30000, +40000 to avoid collisions with base IDs. '
    'Wave 1: requires combined_sp_field_map (Wave 0) to be deployed first. '
    'Depends on: field_map (base table), combined_sp_field_map (view). '
    'T-SQL source: dbo.combined_field_map | Migration task T038.';
```

**Key change from AWS SCT output:**
- Branch 2 `SELECT *` replaced with an explicit 14-column list matching Branch 1 (P2-02 fix).

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Two-branch UNION of simple SELECT statements. No complex constructs. |
| Logic Preservation | 9.5/10 | Both branches preserved. Explicit column list in Branch 2 replaces `SELECT *` — no behavioral change, improves resilience to view structure changes. |
| Performance | 8/10 | Branch 1 is a full table scan of `field_map`. Branch 2 evaluates the entire `combined_sp_field_map` view. UNION deduplication adds a sort step. On typical data sizes this is acceptable. |
| Maintainability | 9.5/10 | Explicit 14-column list in both branches, COMMENT ON VIEW, schema-qualified, clear branch comments. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.3/10** | Exceeds PROD target (8.0). Very simple Wave 1 view. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | `perseus.combined_sp_field_map` (Wave 0) must be deployed before this Wave 1 view |

**Effort breakdown:**
- 0.1 h — Schema correction, replace `SELECT *` with explicit column list in Branch 2
- 0.1 h — Add `COMMENT ON VIEW`, column alias list in header, format DDL
- 0.05 h — Syntax validation with `psql` on DEV

**Deployment prerequisite:** `perseus.combined_sp_field_map` (Wave 0, T038) must be created before this view can be deployed.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
