# Views Operational Runbook — US1 Phase 4

**Project:** Perseus Database Migration (SQL Server to PostgreSQL 17)
**Scope:** 20 deployed views in `perseus` schema, `perseus-postgres-dev` Docker container
**Date:** 2026-03-08
**Author:** Perseus DBA Team
**On-call contacts:** TBD by team

---

## Quick Reference

| Item | Value |
|------|-------|
| Container | `perseus-postgres-dev` |
| Database (DEV) | `perseus_dev` |
| Database (STAGING) | `perseus_staging` |
| DB User | `perseus_admin` |
| Connection | `psql -h localhost -p 5432 -U perseus_admin` |
| Password file | `/Users/pierre.ribeiro/workspace/sharing/sqlserver-to-postgresql-migration/perseus-database/.secrets/postgres_password.txt` |
| MV refresh interval | Every 10 minutes (pg_cron, see section 1) |
| Blocked views | `goo_relationship`, `vw_jeremy_runs` (issue #360) |

---

## 1. Translated Materialized View — Refresh Schedule

### 1.1 Trigger-Based Refresh (Deployed)

The `translated` materialized view is refreshed automatically by triggers on:
- `perseus.material_transition` — fires on INSERT, UPDATE, DELETE
- `perseus.transition_material` — fires on INSERT, UPDATE, DELETE

Both triggers call a refresh function that executes `REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated`. Concurrent refresh requires the `idx_translated_unique` index to be present and valid.

**Verify triggers are active:**
```sql
SELECT trigger_name, event_manipulation, event_object_table, action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'perseus'
  AND event_object_table IN ('material_transition', 'transition_material')
ORDER BY event_object_table, trigger_name;
```

### 1.2 pg_cron Scheduled Refresh (Recommended — Safety Net)

Install a pg_cron job as a safety net to catch any rows that bypass the trigger path (e.g., bulk loads, direct table inserts from migration scripts):

```sql
-- Install pg_cron extension if not present
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule refresh every 10 minutes
SELECT cron.schedule(
    'refresh-translated-mv',
    '*/10 * * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;'
);

-- Verify the job is registered
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'refresh-translated-mv';
```

**To disable during maintenance:**
```sql
SELECT cron.unschedule('refresh-translated-mv');
```

**To re-enable after maintenance:**
```sql
SELECT cron.schedule(
    'refresh-translated-mv',
    '*/10 * * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;'
);
```

### 1.3 Manual Refresh

When an immediate refresh is required (e.g., after a bulk data load or following a trigger failure):

```sql
-- Non-blocking concurrent refresh (preferred — requires idx_translated_unique)
REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;

-- Blocking full refresh (use only if idx_translated_unique is missing or corrupt)
-- WARNING: Locks the view for the full duration
REFRESH MATERIALIZED VIEW perseus.translated;
```

### 1.4 MV Freshness Monitoring

```sql
-- Check MV metadata: is it populated?
SELECT schemaname, matviewname, ispopulated
FROM pg_matviews
WHERE matviewname = 'translated'
  AND schemaname  = 'perseus';

-- Check row count vs baseline (3589 rows on 2026-03-08)
SELECT COUNT(*) AS current_rows,
       3589      AS baseline_rows,
       COUNT(*) - 3589 AS delta
FROM perseus.translated;

-- Check last vacuum/analyze stats (proxy for last refresh activity)
SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, n_live_tup
FROM pg_stat_user_tables
WHERE relname = 'translated'
  AND schemaname = 'perseus';
```

---

## 2. Monitoring — Row Counts for All 20 Views

Run this query to get a snapshot of all deployed view sizes. A count of 0 on any view warrants investigation.

```sql
SELECT view_name, row_count
FROM (
    VALUES
        ('translated',                    (SELECT COUNT(*) FROM perseus.translated)),
        ('vw_lot',                        (SELECT COUNT(*) FROM perseus.vw_lot)),
        ('vw_lot_edge',                   (SELECT COUNT(*) FROM perseus.vw_lot_edge)),
        ('vw_lot_path',                   (SELECT COUNT(*) FROM perseus.vw_lot_path)),
        ('combined_field_map',            (SELECT COUNT(*) FROM perseus.combined_field_map)),
        ('combined_field_map_display_type',(SELECT COUNT(*) FROM perseus.combined_field_map_display_type)),
        ('vw_material_field_map',         (SELECT COUNT(*) FROM perseus.vw_material_field_map)),
        ('vw_material_lineage',           (SELECT COUNT(*) FROM perseus.vw_material_lineage)),
        ('vw_run_details',                (SELECT COUNT(*) FROM perseus.vw_run_details)),
        ('vw_run_summary',                (SELECT COUNT(*) FROM perseus.vw_run_summary)),
        ('vw_container_hierarchy',        (SELECT COUNT(*) FROM perseus.vw_container_hierarchy)),
        ('vw_container_summary',          (SELECT COUNT(*) FROM perseus.vw_container_summary)),
        ('vw_transition_audit',           (SELECT COUNT(*) FROM perseus.vw_transition_audit)),
        ('vw_material_status',            (SELECT COUNT(*) FROM perseus.vw_material_status)),
        ('vw_field_value_summary',        (SELECT COUNT(*) FROM perseus.vw_field_value_summary)),
        ('vw_active_containers',          (SELECT COUNT(*) FROM perseus.vw_active_containers)),
        ('vw_material_properties',        (SELECT COUNT(*) FROM perseus.vw_material_properties)),
        ('vw_process_flow',               (SELECT COUNT(*) FROM perseus.vw_process_flow)),
        ('vw_goo_summary',                (SELECT COUNT(*) FROM perseus.vw_goo_summary)),
        ('vw_operation_log',              (SELECT COUNT(*) FROM perseus.vw_operation_log))
) AS counts(view_name, row_count)
ORDER BY view_name;
```

**Alert threshold:** Any view returning 0 rows that previously had data should trigger a P1 investigation.

---

## 3. Maintenance Procedures

### 3.1 Routine VACUUM ANALYZE

Views themselves do not accumulate dead tuples, but their underlying tables do. Run `VACUUM ANALYZE` on the key tables to keep view query plans fresh:

```sql
-- Key tables backing US1 views
VACUUM ANALYZE perseus.material_transition;
VACUUM ANALYZE perseus.transition_material;
VACUUM ANALYZE perseus.goo;
VACUUM ANALYZE perseus.translated;   -- the MV itself

-- Full schema analyze (weekly)
ANALYZE perseus.material_transition;
ANALYZE perseus.transition_material;
ANALYZE perseus.goo;
```

**Schedule:** Weekly via pg_cron or pg_agent during off-peak hours (suggested: Sunday 02:00).

### 3.2 REINDEX — idx_translated_unique

If `REFRESH MATERIALIZED VIEW CONCURRENTLY` fails with an index corruption error, rebuild the unique index:

```sql
-- Check index validity first
SELECT indexname, indisvalid
FROM pg_indexes
JOIN pg_index ON pg_indexes.indexname::regclass = pg_index.indexrelid
WHERE tablename  = 'translated'
  AND schemaname = 'perseus'
  AND indexname  = 'idx_translated_unique';

-- If indisvalid = false, rebuild the index
-- WARNING: REINDEX locks the table. Use REINDEX CONCURRENTLY on PostgreSQL 12+.
REINDEX INDEX CONCURRENTLY perseus.idx_translated_unique;

-- After rebuilding, verify concurrent refresh works
REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;
```

### 3.3 Bloat Check

Monitor index bloat on `idx_translated_unique` if the MV is refreshed frequently:

```sql
SELECT pg_size_pretty(pg_relation_size('perseus.idx_translated_unique')) AS index_size,
       pg_size_pretty(pg_relation_size('perseus.translated'))             AS table_size;
```

If the index is larger than 2× the table size, schedule a `REINDEX CONCURRENTLY`.

### 3.4 Long-Running Query Detection

Views with recursive CTEs (`vw_lot_path`, `vw_lot_edge`) can accumulate in slow queries under certain data patterns. Monitor with:

```sql
SELECT pid, usename, application_name, state,
       now() - query_start AS duration,
       left(query, 120)    AS query_snippet
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - query_start > INTERVAL '30 seconds'
  AND query ILIKE '%vw_lot%'
ORDER BY duration DESC;
```

Terminate a runaway query:
```sql
SELECT pg_terminate_backend(<pid>);
```

---

## 4. Blocked Views — Status and SLA

The following views were not deployed in US1 due to missing upstream schema information:

| View Name | Issue | Status | SLA | Action Required |
|-----------|-------|--------|-----|-----------------|
| `goo_relationship` | #360 | Blocked — awaiting SQL Server team | TBD by team | SQL Server team to confirm `goo` column list |
| `vw_jeremy_runs` | #360 | Blocked — awaiting SQL Server team | TBD by team | Same blocker as above |

**Impact:** Neither view is referenced by any of the 20 deployed views. No operational degradation while blocked.

**Resolution path:** Once issue #360 is resolved, these views enter the standard deployment pipeline (DEV -> STAGING -> PROD) as a follow-up sprint.

---

## 5. Escalation Thresholds

### P0 — Page On-Call Immediately

- `translated` MV `ispopulated = false` (view is empty and serving no data)
- Any of the 20 views returning errors in application queries
- `idx_translated_unique` is invalid and `REFRESH CONCURRENTLY` is failing
- MV refresh taking > 10 minutes (blocks concurrent refresh queue)

**P0 action:** Follow the [Rollback Runbook](./VIEWS-ROLLBACK-RUNBOOK.md) if the issue cannot be resolved within 30 minutes.

### P1 — Fix Before Next Business Day

- View row counts drop > 20% from the established baseline without a known data event
- pg_cron `refresh-translated-mv` job is inactive or failing silently
- Recursive CTE views (`vw_lot_path`, `vw_lot_edge`) taking > 5 seconds on indexed queries

### P2 — Fix Within 1 Week

- Index bloat on `idx_translated_unique` > 2× table size
- VACUUM on underlying tables not running for > 7 days
- Any view has query plan regression (seq scan replacing index scan)

**On-call contacts:** TBD by team. Update this section before PROD deployment.

---

## 6. Health Check Script

Run this script to verify all 20 views are accessible and returning data. Suitable for inclusion in a monitoring cron job or deployment pipeline gate.

```bash
#!/usr/bin/env bash
# us1-views-health-check.sh
# Usage: PGPASSWORD=$(cat /path/to/password.txt) ./us1-views-health-check.sh
# Returns exit code 0 on all-pass, 1 on any failure.

set -euo pipefail

PSQL="psql -h localhost -p 5432 -U perseus_admin -d perseus_dev -t -A"

VIEWS=(
    "translated"
    "vw_lot"
    "vw_lot_edge"
    "vw_lot_path"
    "combined_field_map"
    "combined_field_map_display_type"
    "vw_material_field_map"
    "vw_material_lineage"
    "vw_run_details"
    "vw_run_summary"
    "vw_container_hierarchy"
    "vw_container_summary"
    "vw_transition_audit"
    "vw_material_status"
    "vw_field_value_summary"
    "vw_active_containers"
    "vw_material_properties"
    "vw_process_flow"
    "vw_goo_summary"
    "vw_operation_log"
)

FAILED=0

echo "[$(date -u +%FT%TZ)] US1 Views Health Check — START"

for VIEW in "${VIEWS[@]}"; do
    COUNT=$($PSQL -c "SELECT COUNT(*) FROM perseus.${VIEW};" 2>&1) || {
        echo "FAIL  perseus.${VIEW} — query error: ${COUNT}"
        FAILED=$((FAILED + 1))
        continue
    }
    echo "PASS  perseus.${VIEW} — ${COUNT} rows"
done

# MV freshness check
MV_STATUS=$($PSQL -c "SELECT ispopulated FROM pg_matviews WHERE matviewname='translated' AND schemaname='perseus';" 2>&1)
if [ "${MV_STATUS}" = "t" ]; then
    echo "PASS  translated MV is populated"
else
    echo "FAIL  translated MV ispopulated=${MV_STATUS}"
    FAILED=$((FAILED + 1))
fi

echo "[$(date -u +%FT%TZ)] US1 Views Health Check — DONE (failures: ${FAILED})"

exit ${FAILED}
```

**Usage:**
```bash
export PGPASSWORD=$(cat /Users/pierre.ribeiro/workspace/sharing/sqlserver-to-postgresql-migration/perseus-database/.secrets/postgres_password.txt)
chmod +x us1-views-health-check.sh
./us1-views-health-check.sh
```
