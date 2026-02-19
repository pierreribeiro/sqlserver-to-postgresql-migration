# Analysis: upstream (T035)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T035
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.upstream` |
| PostgreSQL name | `perseus.upstream` |
| Type | Recursive CTE View |
| Priority | P1 (High) |
| Complexity | 7/10 |
| Wave | Wave 1 (must follow translated in Wave 0) |
| Depends on | `perseus.translated` (materialized view — P0, must be deployed first) |
| Referenced by | Lineage visualization queries, material traceability reports |
| FDW dependency | None |
| SQL Server file | `source/original/sqlserver/10.create-view/10.perseus.dbo.upstream.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/10.perseus.upstream.sql` |

---

## Issue Register

### P0 Issues (Blocks ALL testing and deployment)

None identified. The logic itself is sound; all blocking concerns are at P1 or below.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output, all object references
**Description:** AWS SCT emits `perseus_dbo.upstream` and references `perseus_dbo.translated`. The project mandate is the `perseus` schema throughout. Using `perseus_dbo` will cause `relation "perseus_dbo.translated" does not exist` errors at runtime since the materialized view is deployed under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.` in the CREATE statement and all internal references.

---

#### P1-02 — `CYCLE` clause absence: infinite recursion risk not fully mitigated

**Severity:** P1
**Location:** Recursive term of the CTE
**Description:** The recursive step includes `WHERE pt.destination_material != pt.source_material`, which prevents a single row from referencing itself (a self-loop). However, this guard does NOT prevent multi-node cycles. A cycle of length two or more — for example: material A → material B → material A — will cause the CTE to recurse infinitely. PostgreSQL 14 introduced the `CYCLE` clause (ISO SQL:1999 standard) specifically for this case. The `translated` data model has no declared unique constraint or application-level guarantee that prevents such cycles from existing in `material_transition`/`transition_material`. The cycle risk must be addressed explicitly.

**Fix:** Add `CYCLE child SET is_cycle USING path_array` clause to the CTE (see Proposed DDL). This terminates recursion the moment a node is revisited, without requiring application-level guarantees about the data.

**Reference:** PostgreSQL 14+ — `WITH RECURSIVE ... CYCLE col SET flag USING tracking_column`

---

#### P1-03 — Path string overflow silent truncation

**Severity:** P1
**Location:** Recursive term, `CAST(r.path || r.child || '/' AS VARCHAR(255))`
**Description:** The path accumulator is cast to `VARCHAR(255)` in both the anchor and recursive term. The `m_upstream` table (the persistence target populated by the `reconcile_mupstream` stored procedure) enforces `path` with a `CHECK (length(path) <= 500)` constraint, meaning paths are expected to grow up to 500 characters. A graph that is only 5-6 levels deep with 50-character `material_id` values can overflow 255 characters. In PostgreSQL, casting to `VARCHAR(n)` raises `ERROR: value too long for type character varying(255)` at query time — not silent truncation. The upstream view would therefore fail at runtime on any graph deeper than approximately 4 levels with long material IDs.
**Fix:** Use `TEXT` for the path accumulator throughout. `TEXT` is unbounded and idiomatic in PostgreSQL. The `m_upstream` check constraint (500 chars) is the appropriate external cap at persistence time.

---

### P2 Issues

#### P2-01 — No `search_path` guard (schema qualification only partially applied)

**Severity:** P2
**Location:** View body
**Description:** The view references `translated` without the `perseus.` schema qualifier in the T-SQL original. While the CREATE VIEW statement itself will be `CREATE OR REPLACE VIEW perseus.upstream`, the reference inside the CTE body must also be fully qualified as `perseus.translated`. Unqualified references are resolved via `search_path`, which is a security-relevant configuration that must not be relied upon (Constitution Article VII — Modular Logic Separation).
**Fix:** All references to `translated` inside the view body must be `perseus.translated`.

---

#### P2-02 — `parent` column selected but silently discarded

**Severity:** P2
**Location:** CTE anchor and recursive term — `destination_material AS parent` / `pt.destination_material`
**Description:** The CTE projects five columns (`start_point`, `parent`, `child`, `path`, `level`). The outer `SELECT` only exposes four (`start_point`, `child AS end_point`, `path`, `level`). The `parent` column is computed and carried through every recursion level but never used or exposed. This is harmless at runtime but wastes computation at every level. The `mcgetupstream` function computes `parent` (it uses it as the `neighbor` output column), so the view's design intentionally omits it for the simpler use case. Document this design decision explicitly in the view comment.

---

#### P2-03 — No `OR REPLACE` in refactored DDL

**Severity:** P2
**Location:** CREATE VIEW statement
**Description:** The production DDL should include `CREATE OR REPLACE VIEW` to allow idempotent re-deployment without requiring a prior `DROP`. This is especially important in CI/CD pipelines and re-run scenarios on DEV.

---

### P3 Issues

#### P3-01 — No view comment

**Severity:** P3
**Location:** DDL
**Description:** No `COMMENT ON VIEW` statement is present in either the original or the AWS SCT output. All production objects must be documented (Constitution Article VI — Maintainability).
**Fix:** Add `COMMENT ON VIEW perseus.upstream`.

---

#### P3-02 — `VARCHAR(255)` vs `TEXT` inconsistency with base tables

**Severity:** P3 (subsumed by P1-03 above)
**Location:** Path column type
**Description:** Base tables `material_transition.material_id` and `transition_material.material_id` are `VARCHAR(50)`. The m_upstream persistence table uses `VARCHAR(500)` for path. The view uses `VARCHAR(255)` for path — a middle ground that is inconsistent with both. Changing to `TEXT` (see P1-03) also resolves this inconsistency.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `CREATE VIEW upstream AS WITH upstream AS (...)` | `CREATE OR REPLACE VIEW perseus.upstream AS WITH RECURSIVE upstream AS (...)` | DDL header | `WITH RECURSIVE` is required in PostgreSQL; T-SQL infers it automatically |
| `+` (string concat) | `\|\|` | Recursive term: `r.path + r.child + '/'` | AWS SCT handles this correctly |
| `CAST('/' AS VARCHAR(255))` | `'/'::TEXT` | Anchor term | Widen to TEXT (see P1-03) |
| `CAST(r.path \|\| r.child \|\| '/' AS VARCHAR(255))` | `(r.path \|\| r.child \|\| '/')::TEXT` | Recursive term | Widen to TEXT (see P1-03) |
| Schema `dbo.translated` (implicit) | `perseus.translated` | CTE body | Explicit schema qualification mandatory |
| `perseus_dbo.upstream` | `perseus.upstream` | CREATE VIEW | Correct schema (see P1-01) |
| No cycle protection | `CYCLE child SET is_cycle USING path_array` | CTE declaration | PostgreSQL 14+ standard (see P1-02) |
| Missing | `COMMENT ON VIEW perseus.upstream IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

### What SCT got right

- Added `WITH RECURSIVE` — the single most important syntactic difference for recursive CTEs in PostgreSQL. Without this, the query would fail with a parser error.
- Replaced `+` string concatenation with `||` operator.
- Preserved the `UNION ALL` structure and join condition faithfully.
- Column alias list `(start_point, end_point, path, level)` correctly matches the outer SELECT projection.
- `CAST` syntax is valid PostgreSQL.

### What SCT got wrong or missed

1. **Schema is wrong** — emits `perseus_dbo` instead of `perseus`. All references must be corrected.
2. **No `CYCLE` clause** — SCT does not analyze data model graph properties and cannot infer cycle risk. Left unaddressed.
3. **`VARCHAR(255)` path width preserved** — SCT copies the original cast width without considering that PostgreSQL raises an error (not silent truncation) when the value exceeds the declared length. This is a runtime failure risk on any graph with more than ~4 levels using 50-character IDs.
4. **No schema qualifier on `translated`** — The reference `FROM perseus_dbo.translated AS pt` uses the wrong schema but is at least qualified. After the schema correction, this is resolved; however, SCT did not apply schema qualification independently for correctness.
5. **No `COMMENT ON VIEW`** — SCT never generates documentation metadata.
6. **No `OR REPLACE`** — SCT emits `CREATE OR REPLACE VIEW` in this case, so this is actually correct. Noted for completeness.

**SCT reliability score: 6/10**
The structural conversion (WITH RECURSIVE, ||) is correct. The schema error and missing cycle protection are material defects that would cause deployment failure and potential runtime crashes respectively.

---

## Cycle Risk Analysis

### Data Model Graph Topology

The `upstream` view traverses the graph encoded in `perseus.translated`, which is a JOIN of:

- `material_transition(material_id, transition_id)` — maps a source material to a transition
- `transition_material(transition_id, material_id)` — maps a transition to a destination material

A single "edge" in the lineage graph is: `source_material → [via transition_id] → destination_material`.

The `translated` view exposes this as rows of `(source_material, destination_material, transition_id)`.

The `upstream` CTE traverses edges in the direction: given a `destination_material`, find its `source_material` children, then recursively find their sources. This is a backward traversal of the DAG.

### Is the WHERE Guard Sufficient?

```sql
WHERE pt.destination_material != pt.source_material
```

**Verdict: NO. The guard is necessary but not sufficient for cycle safety.**

- The guard eliminates **self-loops** (a single edge where a material is both source and destination of the same transition). This is the only case it prevents.
- It does **not** prevent **multi-hop cycles**, such as:
  - `A → B`, `B → A` (2-cycle)
  - `A → B → C → A` (3-cycle)
- If such cycles exist in the data, PostgreSQL will recurse until it hits the default `max_stack_depth` (typically around 7,500 levels), at which point it will raise: `ERROR: stack depth limit exceeded`. This terminates the query but may exhaust server resources under concurrent load.

### Can Cycles Exist in Production Data?

- Neither `material_transition` nor `transition_material` has a declared constraint that enforces a DAG invariant.
- Application code (stored procedures `addarc`, `removearc`, `linkunlinkedmaterials`) may enforce DAG integrity, but this is application-level, not database-level enforcement.
- Historical data loaded from SQL Server may contain anomalies.
- The `reconcile_mupstream` stored procedure materializes the `upstream` view into `m_upstream` — if cycles existed when it last ran in SQL Server, the data survived because SQL Server's recursive CTE engine also lacks cycle detection by default.

**Conclusion:** Cycles cannot be ruled out with certainty. The risk is low in a well-maintained production system but non-zero, particularly during data migration and initial DEV/STAGING testing with potentially dirty data.

### Recommendation: Add CYCLE Clause

PostgreSQL 14+ provides the `CYCLE` clause as part of ISO SQL standard compliance. It should be added:

```sql
WITH RECURSIVE upstream AS (
    ...
)
CYCLE child SET is_cycle USING path_array
```

- `child` — the column whose values are tracked for revisitation
- `is_cycle` — a BOOLEAN column added to the output, set TRUE when a cycle is detected for that row
- `path_array` — an ARRAY column tracking the path of visited values (internal use by the engine)

The outer SELECT must then filter `WHERE NOT is_cycle` to exclude cycle rows from the result.

This approach:
1. Prevents infinite recursion unconditionally
2. Exposes cycle rows for diagnostic visibility (can be logged separately if needed)
3. Adds zero overhead when no cycles exist in the data
4. Requires no application-level guarantees about graph topology

**Without the CYCLE clause, the upstream view is a latent production incident waiting for its first cyclic data row.**

---

## Performance Considerations

### The Core Performance Problem

Unlike `mcgetupstream(start_point TEXT)` — which filters the anchor term with `WHERE pt.destination_material = @StartPoint` and therefore only traverses one subtree — the `upstream` **view has no anchor filter**. It expands the **entire graph** for every distinct `destination_material` in `translated`.

For a graph with N nodes and average depth D, this view produces O(N * D) rows and performs O(N * depth) recursive JOIN iterations against `translated` on every query. There is no partial evaluation; PostgreSQL must evaluate the full CTE result set.

### Index Recommendations

The recursive JOIN condition is:

```sql
FROM perseus.translated pt
JOIN upstream r ON pt.destination_material = r.child
```

This means each recursive step looks up rows in `translated` by `destination_material`. The `translated` materialized view already has a unique index:

```sql
CREATE UNIQUE INDEX ix_translated ON perseus.translated (destination_material, source_material, transition_id);
```

Since `destination_material` is the **leading column** of this index, the recursive join `ON pt.destination_material = r.child` is an index seek. This is the correct index. No additional index is needed on `translated` for this access pattern.

However, two secondary concerns arise:

**Index recommendation 1 — Index on `translated(source_material)` for downstream pattern:**
The `downstream` view (and its function equivalents) join on `source_material`. Confirm that index coverage exists for that direction as well (separate concern from upstream).

**Index recommendation 2 — Consider materializing `upstream` itself:**
If `upstream` is queried frequently and the underlying graph is large (thousands of nodes), the view will be slow on every query because the full recursive expansion runs each time. Consider:

- **Option A (preferred for read-heavy workloads):** `CREATE MATERIALIZED VIEW perseus.upstream AS ...` with a `REFRESH MATERIALIZED VIEW CONCURRENTLY` triggered by changes to `translated` (which in turn is triggered by changes to `material_transition`/`transition_material`). This requires a UNIQUE index on the materialized view (on `start_point, end_point` or on `start_point, end_point, path`).
- **Option B (acceptable for low-frequency queries):** Keep as a regular view. The `translated` materialized view already removes the JOIN overhead against the base tables; the recursion itself is the remaining cost.

The task description specifies `upstream` as a regular (non-materialized) view. Option B is the baseline. Option A is a follow-on optimization if performance benchmarks reveal issues.

### Query Plan Notes

Expected execution plan for a query against `upstream`:

```
CTE Scan on upstream
  -> Recursive Union
       -> Seq Scan on translated (anchor — full scan, no filter)
       -> Hash Join
            -> Seq Scan on translated (recursive term scan)
            -> Hash on CTE upstream (working table)
```

The absence of a WHERE clause on the anchor means the anchor always performs a full scan of `translated`. For a materialized view with a few thousand rows this is fine; for tens of thousands of distinct materials it becomes expensive. Monitor with `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` after deployment.

### `max_recursion_depth` / `max_stack_depth`

PostgreSQL does not have a `MAXRECURSION` hint like SQL Server. Recursion depth is bounded by `max_stack_depth` (default ~7.5 MB stack depth, approximately 5,000-10,000 levels for this query). In practice, material lineage graphs are unlikely to be more than 20-30 levels deep. If data quality issues could produce very deep paths, the `CYCLE` clause (P1-02) is the correct mitigation — not a manual depth limit.

### Path Length vs. `VARCHAR(255)` — Runtime Error Scenario

With `material_id` values up to 50 characters and path format `/{child1}/{child2}/.../`:
- Each level adds up to 51 characters (50-char ID + `/`)
- At 5 levels: path ≈ 255 characters (borderline)
- At 6 levels: path > 255 characters → `ERROR: value too long for type character varying(255)`

Using `TEXT` (P1-03 fix) eliminates this class of errors entirely.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

```sql
-- =============================================================================
-- View: perseus.upstream
-- Description: Recursive CTE view that traverses all upstream material lineage
--              paths. For each destination_material in perseus.translated,
--              walks backward through source_material links to enumerate every
--              (start_point, end_point, path, level) tuple reachable upstream.
--
-- NOTE: This view expands the ENTIRE lineage graph (no start-point filter).
--       Use mcgetupstream(text) for single-node traversal in application code.
--
-- NOTE: 'parent' is computed internally by the CTE but intentionally omitted
--       from the projected output. Use mcgetupstream() if 'neighbor' is needed.
--
-- Depends on: perseus.translated (materialized view — must be deployed first)
-- Wave:       Wave 1 (after Wave 0: translated)
-- T-SQL ref:  dbo.upstream
-- Migration:  T035 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.upstream AS
WITH RECURSIVE upstream AS (

    -- Anchor: seed one row per distinct destination_material in translated.
    -- Each destination_material is the start_point of an upstream traversal.
    SELECT
        pt.destination_material          AS start_point,
        pt.destination_material          AS parent,
        pt.source_material               AS child,
        '/'::TEXT                        AS path,
        1                                AS level
    FROM perseus.translated AS pt

    UNION ALL

    -- Recursive term: walk one hop further upstream.
    -- Join translated on destination_material = previous child,
    -- excluding self-referencing edges (necessary but not sufficient guard).
    SELECT
        r.start_point,
        pt.destination_material          AS parent,
        pt.source_material               AS child,
        (r.path || r.child || '/')::TEXT AS path,
        r.level + 1                      AS level
    FROM perseus.translated AS pt
    JOIN upstream AS r
        ON pt.destination_material = r.child
    WHERE pt.destination_material <> pt.source_material

)
-- Cycle detection (PostgreSQL 14+, ISO SQL standard).
-- Tracks visited 'child' values per path. Sets is_cycle = TRUE when a
-- previously-seen child is encountered; path_array is the internal tracking
-- structure. Rows where is_cycle = TRUE are suppressed in the final SELECT.
CYCLE child SET is_cycle USING path_array

SELECT
    start_point,
    child   AS end_point,
    path,
    level
FROM upstream
WHERE NOT is_cycle;

-- Documentation
COMMENT ON VIEW perseus.upstream IS
    'Recursive upstream lineage view. For every destination_material in '
    'perseus.translated, enumerates all (start_point, end_point, path, level) '
    'tuples reachable by following source_material links backward. '
    'Covers the full graph — no start-point filter. '
    'Use mcgetupstream(text) for single-node traversal. '
    'Cycle-safe via PostgreSQL 14 CYCLE clause. '
    'Depends on: perseus.translated (materialized view). '
    'Mirrors: perseus.downstream (inverse traversal direction). '
    'T-SQL source: dbo.upstream | Migration task T035.';
```

### Notes on the Proposed DDL

1. **`'/'::TEXT` cast syntax** — explicit cast using the PostgreSQL idiomatic `::` operator (Constitution Article II — Strict Typing).
2. **`<>` instead of `!=`** — ANSI SQL standard inequality operator (Constitution Article I — ANSI-SQL Primacy). Both work in PostgreSQL; `<>` is preferred.
3. **`CYCLE child SET is_cycle USING path_array`** — PostgreSQL 14+ syntax. The `is_cycle` and `path_array` columns are added to the CTE's internal output but are not projected by the outer SELECT. The `WHERE NOT is_cycle` filter in the outer SELECT suppresses all rows that would form a cycle.
4. **`TEXT` path type** — no length cap in the view; the `m_upstream` table's `CHECK (length(path) <= 500)` constraint enforces the limit at persistence time, which is the correct separation of concerns.
5. **Schema qualification** — every object reference is `perseus.` qualified. No implicit `search_path` reliance.
6. **`OR REPLACE`** — idempotent deployment.

---

## Quality Score Estimate

The score below reflects the **proposed DDL** after all identified issues are resolved.

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 9.5/10 | Valid PostgreSQL 17 syntax. Deducted 0.5 for CYCLE clause being newly introduced (less battle-tested in production, though standard). |
| Logic Preservation | 9/10 | Business logic is faithfully preserved. The CYCLE clause changes behavior only in the presence of cyclic data — which the original query would crash on anyway. Net improvement. Deducted 1.0 for the intentional omission of `parent` in output (design choice, not a defect, but a behavioral delta vs. mcgetupstream). |
| Performance | 7/10 | No anchor-term filter means full-graph expansion on every query. Acceptable for small-to-medium graphs; risk at scale. Score reflects that `translated` is already materialized (major win) and the recursive join uses the leading index column. Monitor and consider materializing upstream if queries are frequent. |
| Maintainability | 9/10 | CTE structure is clear. Column aliases are explicit. Comments and COMMENT ON VIEW present. Constitution-compliant naming and formatting. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no string interpolation, no search_path dependency. Minor deduction for VIEW (not SECURITY DEFINER function), which is appropriate here. |
| **Overall** | **8.6/10** | Meets STAGING gate (>= 7.0, no dimension below 6.0). Approaches PROD target of 8.0. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 1.5 hours |
| Risk | Medium |
| Blocker | `perseus.translated` materialized view must be deployed first (P0 dependency) |

**Effort breakdown:**

- 0.25 h — Schema correction (`perseus_dbo` → `perseus`) and schema-qualification of references
- 0.25 h — Path type widening (`VARCHAR(255)` → `TEXT`)
- 0.5 h — CYCLE clause research, implementation, and testing with synthetic cyclic data
- 0.25 h — Write `COMMENT ON VIEW`, format DDL, validate syntax with `psql -c "\d perseus.upstream"` on DEV
- 0.25 h — Record quality score, update progress tracker

**Risk: Medium** — The CYCLE clause syntax must be validated against the deployed PostgreSQL version. If for any reason the server is running PostgreSQL 13 or earlier (the CYCLE clause requires 14+), an alternative depth-limit guard must be used. Based on project spec (PostgreSQL 17+), this is not expected to be an issue but must be confirmed at deployment time.

**Deployment prerequisite:** `perseus.translated` (T040) must be created and populated before this view can be deployed. Do not deploy `upstream` before `translated` exists.

---

## Appendix: Relationship to mcgetupstream Function

The `upstream` view and the `mcgetupstream` function share the same recursive CTE logic but serve different purposes:

| Aspect | `upstream` view | `mcgetupstream(text)` function |
|--------|----------------|-------------------------------|
| Filter | None — full graph | Anchor filtered by `start_point` parameter |
| Output | `start_point, end_point, path, level` | `start_point, end_point, neighbor, path, level` |
| `parent`/`neighbor` | Computed but dropped | Exposed as `neighbor` column |
| Use case | Exploratory / reporting (all paths) | Application queries (single root) |
| Performance | O(N * D) full expansion | O(subtree size) |
| Cycle safety (proposed) | CYCLE clause | Must also be reviewed (T-function task) |

Both objects must converge to the same cycle-safety strategy. If cycles are confirmed impossible in production data, the CYCLE clause still costs nothing. If they are possible, both objects need the fix.

---

*Generated: 2026-02-19 | Task: T035 | Branch: us1-critical-views | Analyst: database-expert*
