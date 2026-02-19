# Analysis: vw_tom_perseus_sample_prep_materials (T038)

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Task:** T038
**Date:** 2026-02-19
**Analyst:** database-expert agent
**Branch:** us1-critical-views

---

## Object Metadata

| Field | Value |
|-------|-------|
| SQL Server name | `dbo.vw_tom_perseus_sample_prep_materials` |
| PostgreSQL name | `perseus.vw_tom_perseus_sample_prep_materials` |
| Type | Standard View |
| Priority | P3 |
| Complexity | 3/10 |
| Wave | Wave 1 (scheduled here for sequencing; base tables only) |
| Depends on | `perseus.goo` (base table ✅), `perseus.m_downstream` (base table ✅) |
| Blocks | Nothing (no dependent views identified) |
| FDW dependency | None |
| Deprecation Status | DEPRECATION CANDIDATE — see analysis below |
| SQL Server file | `source/original/sqlserver/10.create-view/21.perseus.dbo.vw_tom_perseus_sample_prep_materials.sql` |
| AWS SCT file | `source/original/pgsql-aws-sct-converted/15.create-view/21.perseus.vw_tom_perseus_sample_prep_materials.sql` |

---

## Source Query Analysis

This view aggregates material IDs for a specific set of goo types (40 and 62) — combining the direct materials of those types with their downstream derivatives. The two-branch UNION structure:

**Branch 1 — Downstream derivatives:**
```sql
SELECT ds.end_point AS material_id
FROM goo g
JOIN m_downstream ds ON ds.start_point = g.uid
WHERE g.goo_type_id IN (40, 62)
```
For each goo with type 40 or 62, finds all materials that are downstream of it (all materials that were derived from goo type 40 or 62 via the lineage graph). `m_downstream.end_point` is a TEXT material UID.

**Branch 2 — Direct materials:**
```sql
SELECT g.uid AS material_id
FROM goo g
WHERE g.goo_type_id IN (40, 62)
```
Returns the UID of each goo with type 40 or 62 directly (the goo itself, not just its derivatives).

**Combined result:** A UNION of the direct material UIDs of goo type 40/62 plus all UIDs downstream of them. This effectively returns the complete set of materials that are either of type 40/62 or were derived from a type 40/62 material.

**Business interpretation:**
`goo_type_id IN (40, 62)` represents specific material types of interest (likely a fermentation feedstock or sample prep input type — the "Tom Perseus" name suggests this was a custom report for a specific researcher/analyst named "Tom" working on Perseus project sample preparations). The view collects all sample prep input materials and their lineage derivatives.

**Key observations:**
- `g.uid` is TEXT (goo unique identifier) — `m_downstream.start_point` joins on TEXT.
- `m_downstream.end_point` is TEXT — output `material_id` is TEXT.
- UNION (not UNION ALL) — deduplication is intentional: Branch 1 may include the same UID as Branch 2 (if a material of type 40/62 is also downstream of another material of type 40/62).
- No T-SQL-specific syntax in the body — no CONVERT, ISNULL, GETDATE, string concat.
- The view is placed in Wave 1 in the migration sequence for scheduling purposes, but it technically depends only on base tables and can be deployed in Wave 0.

---

## Deprecation Flag

**STRONG DEPRECATION CANDIDATE.**

Indicators:
1. **Named after a person** — "Tom Perseus" naming convention indicates a person-specific custom report view, not a system view.
2. **Ad-hoc business logic** — filters on specific hardcoded `goo_type_id` values (40, 62) with no comments explaining the business meaning.
3. **No documented consumers** — no other views or stored procedures in the analysis reference this view.
4. **Pattern match** — `vw_tom_perseus_sample_prep_materials` follows the pattern of "named report views" created for specific analysts that are common in mature production databases but often become stale.

**Recommendation:** Before investing refactoring effort, Pierre Ribeiro (project lead) should confirm:
1. Is this view actively used by any application code or reports?
2. Who is "Tom" — is this analyst still with the organization?
3. If deprecated, should it be dropped or preserved in a `deprecated` schema?

**If confirmed deprecated:** Do not deploy. Document in a deprecation tracking record.
**If still in use:** Deploy as described below — the conversion is trivial.

---

## Issue Register

### P0 Issues

None.

---

### P1 Issues

#### P1-01 — Wrong schema: `perseus_dbo` must be `perseus`

**Severity:** P1
**Location:** AWS SCT output — CREATE VIEW header and all table references
**Description:** AWS SCT emits `CREATE OR REPLACE VIEW perseus_dbo.vw_tom_perseus_sample_prep_materials` with `FROM perseus_dbo.goo` and `FROM perseus_dbo.m_downstream`. Both base tables are under `perseus`.
**Fix:** Replace every `perseus_dbo.` prefix with `perseus.`.

---

### P2 Issues

#### P2-01 — Deprecation review required before deployment

**Severity:** P2 (process — not a technical defect)
**Location:** Deployment decision
**Description:** As documented above, this view is named after an individual analyst and contains hardcoded business logic. A deprecation review must be completed before DEV deployment.
**Fix:** Confirm with Pierre Ribeiro before deploying. If deprecated, document and skip.

---

#### P2-02 — Hardcoded `goo_type_id IN (40, 62)` — no comment explaining business meaning

**Severity:** P2 (maintainability)
**Location:** WHERE clause in both branches
**Description:** The magic numbers 40 and 62 have no explanatory comment. If this view is retained, the comment must document what these goo_type_id values represent.
**Fix:** Add comment explaining the business meaning of goo_type_id 40 and 62 in `COMMENT ON VIEW`.

---

#### P2-03 — No `COMMENT ON VIEW` statement

**Severity:** P2
**Location:** DDL
**Description:** No documentation present in the original or AWS SCT output.
**Fix:** Add `COMMENT ON VIEW perseus.vw_tom_perseus_sample_prep_materials IS '...'`.

---

### P3 Issues

#### P3-01 — Unqualified table names in T-SQL original

**Severity:** P3 (informational)
**Location:** T-SQL original — `FROM goo g`, `JOIN m_downstream ds`, `FROM goo g` (no schema)
**Description:** Requires explicit `FROM perseus.goo`, `JOIN perseus.m_downstream` in PostgreSQL.

---

#### P3-02 — UNION vs UNION ALL — deduplication is correct

**Severity:** P3 (design note)
**Location:** Between two branches
**Description:** UNION is correct here — a goo uid of type 40/62 could appear in both Branch 1 (as a downstream of another type 40/62 goo) and Branch 2 (as a direct goo). Deduplication removes such duplicates. Retain UNION.

---

## T-SQL to PostgreSQL Transformations Required

| T-SQL Construct | PostgreSQL Replacement | Location | Notes |
|----------------|----------------------|----------|-------|
| `FROM goo g` (unqualified) | `FROM perseus.goo AS g` | Both branches | Schema + AS keyword |
| `JOIN m_downstream ds` (unqualified) | `JOIN perseus.m_downstream AS ds` | Branch 1 | Schema + AS keyword |
| `CREATE VIEW vw_tom_perseus_sample_prep_materials AS` | `CREATE OR REPLACE VIEW perseus.vw_tom_perseus_sample_prep_materials AS` | DDL header | Schema + OR REPLACE |
| `perseus_dbo.*` (SCT output) | `perseus.*` | All references | Schema correction |
| Missing `COMMENT ON VIEW` | `COMMENT ON VIEW perseus.vw_tom_perseus_sample_prep_materials IS '...'` | Post-CREATE | Constitution Article VI |

---

## AWS SCT Assessment

AWS SCT output (`21.perseus.vw_tom_perseus_sample_prep_materials.sql`):

```sql
CREATE OR REPLACE  VIEW perseus_dbo.vw_tom_perseus_sample_prep_materials (material_id) AS
SELECT
    ds.end_point AS material_id
    FROM perseus_dbo.goo AS g
    JOIN perseus_dbo.m_downstream AS ds
        ON ds.start_point = g.uid
    WHERE g.goo_type_id IN (40, 62)
UNION
SELECT
    g.uid AS material_id
    FROM perseus_dbo.goo AS g
    WHERE g.goo_type_id IN (40, 62);
```

**What SCT got right:**
- Added `CREATE OR REPLACE` — idempotent.
- Added column alias list `(material_id)` in header — correct.
- Added `AS` keywords for table aliases — correct.
- No T-SQL-specific syntax to convert — body is pure ANSI SQL.
- Preserved UNION deduplication — correct.

**What SCT got wrong or missed:**
1. Schema is `perseus_dbo` instead of `perseus` — P1 defect.
2. No `COMMENT ON VIEW` statement.
3. No deprecation warning.

**SCT reliability score: 8/10**
Clean output — schema name is the only defect.

---

## Proposed PostgreSQL DDL

**Dialect:** PostgreSQL 17
**Target schema:** `perseus`

**PREREQUISITE: Confirm with Pierre Ribeiro that this view is not deprecated before deploying.**

```sql
-- =============================================================================
-- View: perseus.vw_tom_perseus_sample_prep_materials
-- Description: Aggregates material UIDs for sample preparation inputs and their
--              downstream lineage derivatives. Returns a UNION of:
--              (1) All materials downstream of goo types 40 and 62
--              (2) All goo records of types 40 and 62 directly
--
--              goo_type_id 40: [VERIFY — likely a specific feedstock type]
--              goo_type_id 62: [VERIFY — likely a specific sample prep input type]
--
--              DEPRECATION CANDIDATE: This view is named after an individual
--              analyst ('Tom Perseus') and contains hardcoded goo_type_id values.
--              Confirm active usage with Pierre Ribeiro before deploying.
--
-- Depends on:  perseus.goo (base table ✅)
--              perseus.m_downstream (base table ✅ — populated by reconcile_mupstream)
-- Blocks:      None
-- Wave:        Wave 1 (can be deployed in Wave 0 — base tables only)
-- T-SQL ref:   dbo.vw_tom_perseus_sample_prep_materials
-- Migration:   T038 | Branch: us1-critical-views | 2026-02-19
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_tom_perseus_sample_prep_materials (
    material_id
) AS

-- Branch 1: Materials downstream of sample prep input types
SELECT
    ds.end_point    AS material_id
FROM perseus.goo AS g
JOIN perseus.m_downstream AS ds
    ON ds.start_point = g.uid
WHERE g.goo_type_id IN (40, 62)

UNION

-- Branch 2: Sample prep input materials directly
SELECT
    g.uid           AS material_id
FROM perseus.goo AS g
WHERE g.goo_type_id IN (40, 62);

-- Documentation
COMMENT ON VIEW perseus.vw_tom_perseus_sample_prep_materials IS
    'Sample preparation material aggregation view. Returns the UNION of: '
    '(1) all materials downstream of goo types 40 and 62 via m_downstream, and '
    '(2) all goo records of type 40 or 62 directly. '
    'goo_type_id 40: [verify business meaning — likely a specific feedstock type]. '
    'goo_type_id 62: [verify business meaning — likely a sample prep input type]. '
    'DEPRECATION CANDIDATE: Person-named view (''Tom Perseus'') with hardcoded type IDs. '
    'Confirm active usage with Pierre Ribeiro before investing further effort. '
    'Depends on: goo (base table), m_downstream (base table, populated by reconcile_mupstream). '
    'T-SQL source: dbo.vw_tom_perseus_sample_prep_materials | Migration task T038.';
```

---

## Quality Score Estimate

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 10/10 | Two-branch UNION of simple SELECT statements — minimal syntax. |
| Logic Preservation | 9/10 | Both branches preserved. UNION deduplication preserved. Minor deduction: hardcoded type IDs (40, 62) are not documented — business meaning unverified. |
| Performance | 8/10 | Branch 1 requires `m_downstream` JOIN on `start_point` — index on `m_downstream.start_point` critical. Branch 2 is a simple filtered scan of `goo`. UNION deduplication adds a sort step. Acceptable for typical data sizes. |
| Maintainability | 7/10 | Simple structure. Score reduced due to: hardcoded type IDs without documentation, person-named view (deprecation risk), no existing documentation. COMMENT ON VIEW improves this. |
| Security | 9.5/10 | Schema-qualified, no dynamic SQL, no search_path dependency. |
| **Overall** | **8.7/10** | Technically exceeds PROD target. Maintainability concern is the main drag. If confirmed active, add business documentation for type IDs 40 and 62 to improve the score. |

---

## Refactoring Effort Estimate

| Item | Detail |
|------|--------|
| Effort | 0.25 hours (if not deprecated) |
| Risk | Low (technical) / High (strategic — deprecation decision pending) |
| Blocker | Deprecation review with Pierre Ribeiro required before deployment |

**Effort breakdown:**
- 0.05 h — Schema correction (3 table references)
- 0.1 h — Add `COMMENT ON VIEW` with deprecation note and business meaning placeholder
- 0.1 h — Confirm with Pierre: is this view used? What do goo_type_id 40 and 62 represent?

**If deprecated:** Zero additional technical effort. Document in tracking as "deprecated, not deployed."
**If retained:** 0.25 h total — one of the simplest conversions in the batch.

---

*Generated: 2026-02-19 | Task: T038 | Branch: us1-critical-views | Analyst: database-expert*
