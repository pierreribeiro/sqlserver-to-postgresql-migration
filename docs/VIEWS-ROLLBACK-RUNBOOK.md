# Views Rollback Runbook — US1 Phase 4

**Project:** Perseus Database Migration (SQL Server to PostgreSQL 17)
**Scope:** 20 deployed views in `perseus` schema
**Date:** 2026-03-08
**Author:** Perseus DBA Team
**RTO:** < 30 minutes for full wave rollback
**RPO:** No data loss (views are read-only objects)

---

## Overview

This runbook covers rollback procedures for the 22 views in US1. Rollback uses the script `scripts/deployment/rollback-object.sh` for individual objects, or the full rollback script in the [Emergency Full Rollback](#emergency-full-rollback) section below.

**20 views are deployed and subject to rollback.** 2 views (`goo_relationship`, `vw_jeremy_runs`) were never deployed (blocked by issue #360) and require no rollback action.

**Critical constraint:** The `translated` materialized view must be rolled back LAST. It is a dependency anchor — `DROP MATERIALIZED VIEW CASCADE` will remove its unique index (`idx_translated_unique`) and any triggers attached to it.

**Rollback window:** 7 days from deployment date (2026-03-08 to 2026-03-15). After this window, rollback requires a formal change request.

---

## Rollback Order

Rollback proceeds in reverse deployment order: Wave 2 first, then Wave 1, then Wave 0. The `translated` materialized view is always the final object dropped.

### Wave 2 — Dependent Views (drop first)

| # | View Name | Type | Rollback Command | Cascade Risk | Notes |
|---|-----------|------|-----------------|--------------|-------|
| 1 | `vw_operation_log` | Standard | `DROP VIEW IF EXISTS perseus.vw_operation_log;` | Low | No dependents |
| 2 | `vw_goo_summary` | Standard | `DROP VIEW IF EXISTS perseus.vw_goo_summary;` | Low | No dependents |
| 3 | `vw_process_flow` | Standard | `DROP VIEW IF EXISTS perseus.vw_process_flow;` | Low | No dependents |
| 4 | `vw_material_properties` | Standard | `DROP VIEW IF EXISTS perseus.vw_material_properties;` | Low | No dependents |
| 5 | `vw_active_containers` | Standard | `DROP VIEW IF EXISTS perseus.vw_active_containers;` | Low | No dependents |
| 6 | `vw_field_value_summary` | Standard | `DROP VIEW IF EXISTS perseus.vw_field_value_summary;` | Low | No dependents |
| 7 | `vw_material_status` | Standard | `DROP VIEW IF EXISTS perseus.vw_material_status;` | Low | No dependents |
| 8 | `vw_transition_audit` | Standard | `DROP VIEW IF EXISTS perseus.vw_transition_audit;` | Low | No dependents |
| 9 | `vw_container_summary` | Standard | `DROP VIEW IF EXISTS perseus.vw_container_summary;` | Medium | Check vw_container_hierarchy |
| 10 | `vw_run_summary` | Standard | `DROP VIEW IF EXISTS perseus.vw_run_summary;` | Medium | Check vw_run_details |

### Wave 1 — Mid-Tier Views

| # | View Name | Type | Rollback Command | Cascade Risk | Notes |
|---|-----------|------|-----------------|--------------|-------|
| 11 | `vw_run_details` | Standard | `DROP VIEW IF EXISTS perseus.vw_run_details;` | Low | After vw_run_summary |
| 12 | `vw_container_hierarchy` | Standard | `DROP VIEW IF EXISTS perseus.vw_container_hierarchy;` | Low | After vw_container_summary |
| 13 | `vw_material_lineage` | Standard | `DROP VIEW IF EXISTS perseus.vw_material_lineage;` | Low | After vw_material_field_map |
| 14 | `vw_material_field_map` | Standard | `DROP VIEW IF EXISTS perseus.vw_material_field_map;` | Low | No dependents |
| 15 | `combined_field_map_display_type` | Standard | `DROP VIEW IF EXISTS perseus.combined_field_map_display_type;` | Low | After combined_field_map |
| 16 | `combined_field_map` | Standard | `DROP VIEW IF EXISTS perseus.combined_field_map;` | Medium | Source for display_type view |
| 17 | `vw_lot_path` | Recursive CTE | `DROP VIEW IF EXISTS perseus.vw_lot_path;` | Low | After vw_lot_edge |
| 18 | `vw_lot_edge` | Recursive CTE | `DROP VIEW IF EXISTS perseus.vw_lot_edge;` | Low | After vw_lot_path |

### Wave 0 — Foundation Views (drop second-to-last)

| # | View Name | Type | Rollback Command | Cascade Risk | Notes |
|---|-----------|------|-----------------|--------------|-------|
| 19 | `vw_lot` | Standard | `DROP VIEW IF EXISTS perseus.vw_lot;` | High | After lot path/edge views |

### Final — Materialized View (drop last)

| # | View Name | Type | Rollback Command | Cascade Risk | Notes |
|---|-----------|------|-----------------|--------------|-------|
| 20 | `translated` | Materialized | `DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;` | **CRITICAL** | Drops idx_translated_unique + triggers |

---

## Emergency Rollback: `translated` Materialized View

The `translated` materialized view is the most critical object in US1. Before dropping it, confirm the following:

**Pre-drop checklist:**
- [ ] All Wave 2 and Wave 1 views have been dropped successfully
- [ ] `vw_lot` has been dropped
- [ ] No application connections are actively querying `translated` (check `pg_stat_activity`)
- [ ] The upstream procedure `mcgetupstream` does not have an active session using `translated`
- [ ] Team lead has approved the rollback

**Impact of `DROP MATERIALIZED VIEW CASCADE`:**
- Drops `idx_translated_unique` (unique index required for `REFRESH CONCURRENTLY`)
- Drops any triggers referencing `translated` (refresh triggers on `material_transition`, `transition_material`)
- Any pg_cron jobs referencing `translated` will error until the view is redeployed

**Drop command:**
```sql
-- Confirm active connections first
SELECT pid, usename, application_name, state, query
FROM pg_stat_activity
WHERE query ILIKE '%translated%'
  AND state = 'active';

-- Drop the materialized view (only after confirming no active sessions)
DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;
```

**To verify it is gone:**
```sql
SELECT COUNT(*) FROM pg_matviews WHERE matviewname = 'translated';
-- Expected: 0
```

---

## Full Rollback Script

Run this script to perform a complete US1 rollback. Execute as `perseus_admin`.

```sql
-- =============================================================================
-- US1 Full Rollback Script
-- Run as: psql -h localhost -p 5432 -U perseus_admin -d perseus_dev -f rollback-us1.sql
-- Date: 2026-03-08
-- =============================================================================

BEGIN;

-- Wave 2: Dependent views
DROP VIEW IF EXISTS perseus.vw_operation_log;
DROP VIEW IF EXISTS perseus.vw_goo_summary;
DROP VIEW IF EXISTS perseus.vw_process_flow;
DROP VIEW IF EXISTS perseus.vw_material_properties;
DROP VIEW IF EXISTS perseus.vw_active_containers;
DROP VIEW IF EXISTS perseus.vw_field_value_summary;
DROP VIEW IF EXISTS perseus.vw_material_status;
DROP VIEW IF EXISTS perseus.vw_transition_audit;
DROP VIEW IF EXISTS perseus.vw_container_summary;
DROP VIEW IF EXISTS perseus.vw_run_summary;

-- Wave 1: Mid-tier views
DROP VIEW IF EXISTS perseus.vw_run_details;
DROP VIEW IF EXISTS perseus.vw_container_hierarchy;
DROP VIEW IF EXISTS perseus.vw_material_lineage;
DROP VIEW IF EXISTS perseus.vw_material_field_map;
DROP VIEW IF EXISTS perseus.combined_field_map_display_type;
DROP VIEW IF EXISTS perseus.combined_field_map;
DROP VIEW IF EXISTS perseus.vw_lot_path;
DROP VIEW IF EXISTS perseus.vw_lot_edge;

-- Wave 0: Foundation views
DROP VIEW IF EXISTS perseus.vw_lot;

COMMIT;

-- translated MV is dropped outside a transaction block (DDL with CASCADE)
DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;

-- Verify rollback complete
SELECT COUNT(*) AS views_remaining
FROM pg_views
WHERE schemaname = 'perseus'
  AND viewname IN (
    'vw_lot', 'vw_lot_edge', 'vw_lot_path', 'combined_field_map',
    'combined_field_map_display_type', 'vw_material_field_map',
    'vw_material_lineage', 'vw_run_details', 'vw_run_summary',
    'vw_container_hierarchy', 'vw_container_summary', 'vw_transition_audit',
    'vw_material_status', 'vw_field_value_summary', 'vw_active_containers',
    'vw_material_properties', 'vw_process_flow', 'vw_goo_summary',
    'vw_operation_log'
  );
-- Expected: 0

SELECT COUNT(*) AS mvs_remaining
FROM pg_matviews
WHERE schemaname = 'perseus'
  AND matviewname = 'translated';
-- Expected: 0
```

---

## Blockers — Views NOT Subject to Rollback

The following views were never deployed and require no rollback action:

| View Name | Status | Issue | Reason Blocked |
|-----------|--------|-------|----------------|
| `goo_relationship` | Never deployed | #360 | Dependency on `goo` table columns unavailable from SQL Server team |
| `vw_jeremy_runs` | Never deployed | #360 | Same blocker — awaiting upstream schema confirmation |

These views will be addressed in a follow-up sprint once issue #360 is resolved.

---

## Post-Rollback Verification

After completing rollback, run the following to confirm clean state:

```sql
-- All US1 views are gone
SELECT viewname
FROM pg_views
WHERE schemaname = 'perseus'
ORDER BY viewname;

-- translated MV is gone
SELECT matviewname
FROM pg_matviews
WHERE schemaname = 'perseus';

-- No orphan indexes on translated
SELECT indexname
FROM pg_indexes
WHERE tablename = 'translated'
  AND schemaname = 'perseus';
```

**Expected result:** No rows returned from any of the above queries (for US1 objects).

---

## Escalation

If rollback fails or a view cannot be dropped due to unknown dependents, run:

```sql
SELECT dependent_ns.nspname AS dependent_schema,
       dependent_view.relname AS dependent_view,
       source_ns.nspname AS source_schema,
       source_table.relname AS source_view
FROM pg_depend
JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.oid
JOIN pg_class AS source_table ON pg_depend.refobjid = source_table.oid
JOIN pg_namespace AS dependent_ns ON dependent_view.relnamespace = dependent_ns.oid
JOIN pg_namespace AS source_ns ON source_table.relnamespace = source_ns.oid
WHERE source_table.relname = 'translated'  -- replace with the blocked view name
  AND source_ns.nspname = 'perseus'
  AND dependent_view.relname <> source_table.relname;
```

This query reveals hidden dependents that must be dropped before the target view.
