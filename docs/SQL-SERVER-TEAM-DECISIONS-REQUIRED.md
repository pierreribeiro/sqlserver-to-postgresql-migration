# SQL Server Team — Decisions Required for PostgreSQL Migration

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Document type:** Escalation — decisions/clarifications required before migration can proceed
**Prepared by:** Migration Team (Claude Code / Pierre Ribeiro)
**Date:** 2026-02-19
**Reference tasks:** T034, T035, T036, T037, T038 (Phase 1 Analysis — US1 Critical Views)
**GitHub Issue:** See link in progress-tracker.md

---

## Summary

During Phase 1 analysis of the 22 Perseus views (US1), the migration team identified **4 topics** that require decisions or clarifications from the SQL Server development team before migration work can proceed safely. These items cannot be resolved by the migration team alone — they require knowledge of the live SQL Server production state and business intent.

---

## Topic 1 — CRITICAL: Missing Columns in `goo` and `fatsmurf` Tables

### What we found

The following views reference columns that **do not exist** in either the extracted SQL Server DDL or the deployed PostgreSQL `perseus` schema:

| Missing Column | Table | Referenced in View | Branch |
|---------------|-------|--------------------|--------|
| `merged_into` | `dbo.goo` | `goo_relationship` | Branch 1 (`WHERE merged_into IS NOT NULL`) |
| `source_process_id` | `dbo.goo` | `goo_relationship` | Branch 2 (`JOIN goo c ON c.source_process_id = fs.id`) |
| `goo_id` | `dbo.fatsmurf` | `goo_relationship` | Branch 2 (`JOIN fatsmurf fs ON fs.goo_id = p.id`) |
| `tree_scope_key` | `dbo.goo` | `vw_jeremy_runs` | Recursive nested-set traversal |
| `tree_left_key` | `dbo.goo` | `vw_jeremy_runs` | Recursive nested-set traversal |
| `tree_right_key` | `dbo.goo` | `vw_jeremy_runs` | Recursive nested-set traversal |

### Verified facts

- The extracted `CREATE TABLE [dbo].[goo]` DDL has **23 columns** — none of them is `merged_into`, `source_process_id`, `tree_scope_key`, `tree_left_key`, or `tree_right_key`.
- The extracted `CREATE TABLE [dbo].[fatsmurf]` DDL has **18 columns** — none of them is `goo_id`.
- The deployed `perseus.goo` table in `perseus_dev` (PostgreSQL) mirrors the extracted DDL exactly — 20 columns, same missing columns.
- No `ALTER TABLE` statements adding these columns were found in the extraction artifacts (`source/original/sqlserver/`).
- The same missing columns are referenced in **old stored procedures** (`GetUpStream`, `GetDownStream`, `sp_move_node`) that also appear to be legacy code.

### Questions for the SQL Server team

**Q1.1** — Do columns `merged_into` and `source_process_id` currently exist in the **live production** `dbo.goo` table in SQL Server?

**Q1.2** — Does column `goo_id` currently exist in the **live production** `dbo.fatsmurf` table in SQL Server?

**Q1.3** — Do columns `tree_scope_key`, `tree_left_key`, `tree_right_key` currently exist in the **live production** `dbo.goo` table?

**Q1.4** — If these columns exist in production but were not captured in the extraction: can you provide the `ALTER TABLE` DDL that adds them? The migration team will add the missing columns to the PostgreSQL `goo` and `fatsmurf` tables before deploying these views.

**Q1.5** — If these columns do **not** exist in production: the views `goo_relationship` (Branches 1 and 2) and `vw_jeremy_runs` were already broken/non-functional in SQL Server. Please confirm, so the migration team can mark these view branches as deprecated rather than investing effort migrating broken logic.

### Impact if unresolved

- `goo_relationship` Branch 1 and Branch 2 cannot be deployed → only Branch 3 (hermes FDW dependency) survives
- `vw_jeremy_runs` is fully undeployable (all recursive logic depends on `tree_*` columns)
- Priority: **P1 blocker** — must be resolved before Phase 2 refactoring begins for these two views

---

## Topic 2 — Deprecation Candidates: `vw_tom_perseus_sample_prep_materials` and `vw_jeremy_runs`

### What we found

Two views appear to be **personal/custom report views** named after individuals:

#### `vw_tom_perseus_sample_prep_materials`
- **Logic:** Retrieves material IDs for `goo_type_id IN (40, 62)` — specific material types — joined with `m_downstream` traversal
- **Complexity:** Low (3/10)
- **Migration blockers:** None (base tables deployed ✅)
- **Concern:** Named after a person ("Tom Perseus"), suggesting a custom report. If this user/team no longer needs it, it need not be migrated.

#### `vw_jeremy_runs`
- **Logic:** Complex recursive CTE combining nested-set traversal, `goo_relationship`, and `hermes` FDW data to find runs with cell harvests or liquid separations
- **Complexity:** High (6/10)
- **Migration blockers:** 3 independent blockers — hermes FDW not configured, `goo_relationship` column drift (Topic 1), `goo.tree_*` columns missing (Topic 1)
- **Concern:** Named after a person ("Jeremy"), suggesting a custom report. Has the highest combination of complexity and blockers of any P3 view.

### Questions for the SQL Server team

**Q2.1** — Is `vw_tom_perseus_sample_prep_materials` actively used in production (application queries, reports, other objects)? If not used, confirm deprecation.

**Q2.2** — Is `vw_jeremy_runs` actively used in production? If not, confirm deprecation. If yes: is the current SQL Server version functional (given the `tree_*` column question from Topic 1)?

**Q2.3** — If `vw_jeremy_runs` is to be migrated: the `goo_type_id IN (40, 62)` and `smurf_id IN (23, 25)` constants — what do they represent? (The migration team needs this context to validate correctness after migration.)

### Impact if unresolved

- Migration team will assume both views must be migrated → invest effort on complex views that may be dead code
- For `vw_jeremy_runs` specifically: migration is impossible until Topics 1 and 3 are also resolved

---

## Topic 3 — hermes FDW: Schema and Connection Details Required

### What we found

Three views depend on the `hermes` linked server (SQL Server) which will become a Foreign Data Wrapper in PostgreSQL:

| View | hermes objects used |
|------|---------------------|
| `goo_relationship` (Branch 3) | `hermes.run` (`feedstock_material`, `resultant_material`) |
| `hermes_run` | `hermes.run` (full row: 12 columns) + `hermes.run_condition_value` |
| `vw_jeremy_runs` | `hermes.run` + `hermes.run_condition_value` |

The migration team needs the hermes database schema to:
1. Configure the `postgres_fdw` server and import the foreign schema
2. Validate column types in the view DDL (one type mismatch already found: `stop_time` appears to be `NUMERIC(10,2)` — elapsed time — but aliased as `duration`)

### Questions for the SQL Server team

**Q3.1** — Please provide the DDL (or column list with types) for the `hermes.dbo.run` table — specifically: `id`, `experiment_id`, `local_id`, `description`, `created_on`, `strain`, `max_yield`, `max_titer`, `start_time`, `stop_time`, `feedstock_material`, `resultant_material`, `tank` columns and their data types.

**Q3.2** — Please provide the DDL (or column list with types) for `hermes.dbo.run_condition_value` — specifically: `id`, `run_id`, `master_condition_id`, `value` and their data types.

**Q3.3** — Is `hermes.run.stop_time` an elapsed duration (NUMERIC/FLOAT seconds or minutes) or a stop timestamp (DATETIME)? The alias `AS duration` in `hermes_run` view suggests elapsed time, but the column name suggests timestamp.

**Q3.4** — What is the connection string / server name for the hermes database that will be configured as a `postgres_fdw` server? (host, port, database name, credentials or credential manager reference)

**Q3.5** — Are `feedstock_material` and `resultant_material` in `hermes.run` case-sensitive UIDs? (This affects whether `=` or `ILIKE` should be used in the join conditions.)

### Impact if unresolved

- `goo_relationship` Branch 3, `hermes_run`, and `vw_jeremy_runs` cannot be deployed
- Type mismatches discovered only at runtime could cause data corruption
- FDW configuration cannot begin without connection details

---

## Topic 4 — Case Sensitivity of Material UIDs: SQL Server vs PostgreSQL

### What we found

AWS SCT introduced `::CITEXT` (case-insensitive text type) on several string comparisons involving material UIDs in `goo_relationship` and `hermes_run`:

**SCT output (incorrect):**
```sql
WHERE COALESCE(r.feedstock_material, '')::CITEXT != COALESCE(r.resultant_material, '')::CITEXT
```

**SQL Server original:**
```sql
WHERE ISNULL(r.feedstock_material, '') != ISNULL(r.resultant_material, '')
```

### Context

SQL Server uses the `SQL_Latin1_General_CP1_CI_AS` collation on the Perseus database — **CI = Case Insensitive**. This means all string comparisons in SQL Server are case-insensitive by default.

PostgreSQL uses case-sensitive comparisons by default (`text` type, `=` operator). SCT attempted to preserve case-insensitivity by using `::CITEXT`, but this was applied inconsistently and only in the WHERE clause (not in JOIN conditions).

Material UIDs in the `goo` table (`uid` column, e.g. `m12345`, `P-2026-001`) are used as foreign keys across multiple tables.

### Questions for the SQL Server team

**Q4.1** — Are material UIDs (`goo.uid`, `material_transition.material_id`, `transition_material.material_id`) stored with consistent casing in production? (e.g., always lowercase `m12345`, or could they be `M12345` in some rows?)

**Q4.2** — Are there any join conditions or WHERE clauses in the application layer that rely on case-insensitive UID matching? (e.g., application code passing `M12345` expecting to match `m12345`)

**Q4.3** — For the `hermes.run.feedstock_material` and `hermes.run.resultant_material` columns — are these UIDs stored with the same casing convention as `goo.uid`?

### Migration team's proposed approach

If UIDs are stored with consistent casing (always same case):
→ Use standard `TEXT` type with case-sensitive `=` comparison (faster, simpler)

If UIDs may have mixed casing:
→ Add `LOWER()` normalization at the application layer boundary or use `CITEXT` consistently on all UID columns (not just in WHERE clauses)

### Impact if unresolved

- Silent data correctness bugs: rows that match in SQL Server (case-insensitive) may not match in PostgreSQL (case-sensitive)
- Affects all views that join on `uid` columns across tables

---

## Response Template

Please respond to each question using the following format:

```
Q1.1: [YES / NO / UNKNOWN — explanation]
Q1.2: [YES / NO / UNKNOWN — explanation]
Q1.3: [YES / NO / UNKNOWN — explanation]
Q1.4: [DDL provided / not applicable]
Q1.5: [Confirmed deprecated / Confirmed functional — please provide column DDL]
Q2.1: [Active in production / Not used — confirm deprecation]
Q2.2: [Active / Not used / Functional/broken status]
Q2.3: [Description of constants]
Q3.1: [Column list with types]
Q3.2: [Column list with types]
Q3.3: [NUMERIC elapsed / DATETIME timestamp — clarify unit if NUMERIC]
Q3.4: [Connection details]
Q3.5: [Case-sensitive / Case-insensitive]
Q4.1: [Consistent casing / Mixed casing — describe convention]
Q4.2: [Yes — describe / No]
Q4.3: [Same convention / Different — describe]
```

---

## Timeline

These decisions are on the critical path for US1 (22 views migration). The migration team can proceed with views that have no dependency on these topics (19 of 22 views). The 3 blocked views (`goo_relationship`, `hermes_run`, `vw_jeremy_runs`) are held pending your response.

**Requested response by:** As soon as possible (before Phase 2 refactoring begins — target 2026-02-26)

---

*Document generated by migration team. Reference: `source/building/pgsql/refactored/15.create-view/analysis/` for full per-view analysis files.*
