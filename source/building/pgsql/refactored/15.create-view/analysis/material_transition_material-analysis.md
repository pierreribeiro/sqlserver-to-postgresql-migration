# Analysis: material_transition_material (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.material_transition_material` |
| PostgreSQL name | `perseus.material_transition_material` |
| Type | Standard View |
| Priority | P2 |
| Complexity | 2/10 |
| Wave | Wave 1 (depends on `translated`) |
| Depends on | `perseus.translated` (materialized view — deployed in Wave 0) |
| Blocks | Nothing |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/8.perseus.dbo.material_transition_material.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/8.perseus.material_transition_material.sql` |

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output, CREATE VIEW header and FROM clause
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.material_transition_material` and references `FROM perseus_dbo.translated`. The production schema is `perseus` throughout. The `translated` materialized view is deployed under `perseus`, not `perseus_dbo`. Using `perseus_dbo` will cause `relation "perseus_dbo.translated" does not exist` at runtime.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation is present in the original or the AWS SCT output. Constitution Article VI requires all production objects to be documented.
**Fix:** Add `COMMENT ON VIEW perseus.material_transition_material IS '...'`.

---

### P3 Issues

#### P3-01 — Column alias list in CREATE OR REPLACE VIEW header is optional but adds clarity

**Severity:** P3
**Location:** CREATE VIEW header
**Description:** AWS SCT correctly emits the column alias list `(start_point, transition_id, end_point)` in the CREATE VIEW header. This is a good practice for documentation purposes and should be retained in the production DDL. The T-SQL original does not include it.
**Note:** Retaining column alias list is a positive practice — not an issue requiring a fix, but it should be deliberately preserved.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `FROM translated` (unqualified) | `FROM perseus.translated` | FROM clause | Explicit schema qualification mandatory |
| `CREATE VIEW material_transition_material AS` | `CREATE OR REPLACE VIEW perseus.material_transition_material AS` | DDL header | Add schema prefix and OR REPLACE |
| (no other T-SQL-specific constructs) | — | — | View body is pure ANSI SQL with only column aliases |

---

## AWS SCT Assessment

AWS SCT output (`8.perseus.material_transition_material.sql`):

```sql
CREATE OR REPLACE VIEW perseus_dbo.material_transition_material (start_point, transition_id, end_point) AS
SELECT
    source_material AS start_point, transition_id, destination_material AS end_point
    FROM perseus_dbo.translated;
```

**What SCT got right:**
- Retained the projection and column aliases (`start_point`, `transition_id`, `end_point`) — these are correct.
- Added `CREATE OR REPLACE` — idempotent deployment.
- Added explicit column alias list in header.
- No T-SQL-specific syntax to convert (this view is already near-ANSI SQL).

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — will fail at deployment.
2. No `COMMENT ON VIEW` statement.

**SCT reliability score: 7/10**
The structural conversion is essentially a schema rename. The only defect is the wrong schema name.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.material_transition_material
-- Description: Thin wrapper over the translated materialized view.
--              Exposes source_material, transition_id, and destination_material
--              with intuitive aliases: start_point, transition_id, end_point.
--              Used by lineage queries that need a named relational projection
--              of the translated graph edges.
--
-- Depends on: perseus.translated (materialized view — Wave 0, must be deployed first)
-- Wave:       Wave 1
-- T-SQL ref:  dbo.material_transition_material
-- Migration:  T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.material_transition_material (
    start_point,
    transition_id,
    end_point
) AS
SELECT
    source_material      AS start_point,
    transition_id,
    destination_material AS end_point
FROM perseus.translated;

-- Documentation
COMMENT ON VIEW perseus.material_transition_material IS
    'Projection of the translated materialized view with semantic column aliases. '
    'Exposes source_material as start_point, transition_id unchanged, and '
    'destination_material as end_point. Used by lineage queries requiring named '
    'graph edge access. '
    'Depends on: perseus.translated (materialized view). '
    'T-SQL source: dbo.material_transition_material | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Single-clause SELECT — simplest possible view. No syntax risk. |
| Logic Preservation | 10/10 | Business logic is identical: pure column alias renaming over translated. |
| Performance | 9/10 | Single table scan of a materialized view with index. Negligible overhead. |
| Maintainability | 9/10 | Clear column aliases, COMMENT ON VIEW present, schema-qualified. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **9.5/10** | Exceeds PROD target (8.0). Trivial conversion — lowest risk of all 22 views. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours |
| Risk | Low |
| Blocker | `perseus.translated` materialized view must be deployed first (Wave 0 dependency) |

**Effort breakdown:**
- 0.1 h — Schema correction (`perseus_dbo` → `perseus`)
- 0.1 h — Add `COMMENT ON VIEW`, format DDL
- 0.05 h — Syntax validation with `psql` on DEV

**Deployment prerequisite:** `perseus.translated` (T040) must be created and populated before this view can be deployed.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
