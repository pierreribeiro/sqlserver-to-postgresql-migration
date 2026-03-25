# US7 CITEXT Pipeline — Debug Round 5 (Bugs 11-14)

## Context

After Debug Round 4, the pipeline ran (run_id `8e43b553e3e3`). Resilience layer worked — errors logged, pipeline continued. But **34 errors** across phases + false "success" message revealed 4 bugs.

**Error summary from run:**
- `00-preflight`: 2 WARNING (phantom columns — correct behavior)
- `02-alter-columns`: 29 ERROR (views blocking ALTER — never dropped)
- `02b-alter-cache-tables`: 5 ERROR (same cause)
- Phase 5: TypeError on `log_dir` kwarg
- Final message: "All phases completed successfully" (wrong)

---

## Bug 12 (P0 CRITICAL): `get_snapshot()` can't parse multi-line DDL

**Root cause (confirmed via DB diagnostic):**

`pg_get_viewdef()` returns multi-line DDL. `snapshot_object()` stores it correctly in PostgreSQL. But `get_snapshot()` reads via `psql -t -A` and parses with `splitlines()` + `split("|")`. Multi-line DDL becomes multiple output lines — the first line has only 5 fields (not 6), so `len(parts) >= 6` fails silently. **ALL 20 views are silently dropped from the return list.** `_drop_from_snapshot()` gets an empty view list → never drops views → Phase 2a/2b ALTERs fail.

Additionally, 7/20 views have `||` (SQL concatenation) in DDL, which also breaks `split("|")`.

**Fix (2 changes):**

1. **`snapshot_object()`** — normalize DDL to single-line before storing:
   ```python
   safe_ddl = " ".join(ddl.split())
   ```

2. **`get_snapshot()`** — parse with `rsplit`/limited `split` to handle `|` in DDL:
   ```python
   rest, _, status = line.rpartition("|")
   parts = rest.split("|", 4)
   if len(parts) >= 5:
       objects.append({
           "object_type": parts[0].strip(),
           "schema_name": parts[1].strip(),
           "object_name": parts[2].strip(),
           "depth": int(parts[3].strip()),
           "ddl": parts[4].strip(),
           "status": status.strip(),
       })
   ```

**File:** `scripts/post-migration/lib/backup.py`

---

## Bug 11 (P2): Spurious DROP INDEX errors on constraint-backing indexes

**22 errors** like `cannot drop index uq_coa_name because constraint uq_coa_name on table coa requires it`.

**Root cause:** `discover_indexes()` finds ALL indexes on target columns including those backing UNIQUE/PK constraints. `DROP INDEX` fails on these because PostgreSQL requires `DROP CONSTRAINT` instead.

**But do they need to be dropped at all?** **No.** PostgreSQL can `ALTER COLUMN TYPE citext` on columns with UQ/PK constraints — the engine rebuilds the index automatically. These 22 DROP attempts are unnecessary.

**Fix:** Filter out constraint-backing indexes in `discover_indexes()`:
```sql
AND NOT EXISTS (SELECT 1 FROM pg_constraint pc WHERE pc.conindid = i.oid)
```

**File:** `scripts/post-migration/preflight_check.py`

---

## Bug 13 (P1): `run_generate_report()` wrong kwarg

`log_dir=self.log_dir` → should be `report_dir=self.log_dir`.

**File:** `scripts/post-migration/run_all.py` (line ~307)

---

## Bug 14 (P1): Pipeline reports success despite 34 errors

`result["success"]` is only set to `False` on phase-level exceptions. Per-object errors don't affect it.

**Fix:** After `get_error_summary()`, check for ERROR/FATAL:
```python
for phase_data in summary.values():
    if isinstance(phase_data, dict):
        if phase_data.get("ERROR", 0) > 0 or phase_data.get("FATAL", 0) > 0:
            result["success"] = False
            break
```

**File:** `scripts/post-migration/run_all.py`

---

## Implementation Plan

### Step 1: Fix Bug 12 — DDL normalization + robust parsing

**File:** `scripts/post-migration/lib/backup.py`

**In `snapshot_object()`:** Add DDL normalization before the INSERT:
```python
safe_ddl = " ".join(ddl.split())  # collapse whitespace, single-line
```
Use `safe_ddl` in the SQL escaping instead of raw `ddl`.

**In `get_snapshot()`:** Replace current parsing:
```python
# Current (broken):
parts = line.split("|")
if len(parts) >= 6:
    ...

# Fixed:
rest, _, status = line.rpartition("|")
parts = rest.split("|", 4)
if len(parts) >= 5:
    objects.append({
        "object_type": parts[0].strip(),
        "schema_name": parts[1].strip(),
        "object_name": parts[2].strip(),
        "depth": int(parts[3].strip()),
        "ddl": parts[4].strip(),
        "status": status.strip(),
    })
```

### Step 2: Fix Bug 11 — Filter constraint-backing indexes

**File:** `scripts/post-migration/preflight_check.py`

In `discover_indexes()`, add to the WHERE clause:
```sql
AND NOT EXISTS (SELECT 1 FROM pg_constraint pc WHERE pc.conindid = i.oid)
```

One line added. No other files need changes.

### Step 3: Fix Bug 13 + Bug 14

**File:** `scripts/post-migration/run_all.py`

Bug 13: Change `log_dir=self.log_dir` → `report_dir=self.log_dir`

Bug 14: After error summary capture, add success check loop (5 lines).

### Step 4: Update debug logbook

**File:** `docs/debugging/post-migration/debug-logbook.md`

Add Debug Round 5 section documenting Bugs 11-14.

---

## Files Modified (4)

| File | Bug | Change |
|------|-----|--------|
| `lib/backup.py` | 12 | DDL single-line normalization in `snapshot_object()` + `rpartition` parsing in `get_snapshot()` |
| `preflight_check.py` | 11 | One WHERE clause added to `discover_indexes()` |
| `run_all.py` | 13, 14 | Fix kwarg name + success flag from error summary |
| `debug-logbook.md` | — | Document Round 5 |

---

## Pre-execution Cleanup

```bash
# Clean manifest for fresh run
rm -f scripts/post-migration/manifest.json

# Clean backup table (stale data from broken run)
docker exec perseus-postgres-dev psql -U perseus_admin -d perseus_dev -c \
  "DELETE FROM public.citext_migration_backup WHERE run_id = '8e43b553e3e3';"
```

## Verification

```bash
cd scripts/post-migration

# 1. Full pipeline run
python run-all.py --config config/citext-conversion.yaml

# 2. Verify ZERO errors in Phase 2a/2b (views dropped correctly this time)
docker exec perseus-postgres-dev psql -U perseus_admin -d perseus_dev -t -c \
  "SELECT phase, severity, COUNT(*) FROM public.citext_migration_error_log \
   WHERE run_id = (SELECT DISTINCT run_id FROM public.citext_migration_error_log ORDER BY run_id DESC LIMIT 1) \
   GROUP BY phase, severity ORDER BY phase;"

# 3. Verify all views were dropped AND recreated (status = 'recreated', not 'backed_up')
docker exec perseus-postgres-dev psql -U perseus_admin -d perseus_dev -t -c \
  "SELECT object_type, status, COUNT(*) FROM public.citext_migration_backup \
   WHERE run_id = (SELECT DISTINCT run_id FROM public.citext_migration_backup ORDER BY run_id DESC LIMIT 1) \
   GROUP BY object_type, status ORDER BY object_type, status;"

# 4. Verify no spurious index drop errors (Bug 11 eliminated)
docker exec perseus-postgres-dev psql -U perseus_admin -d perseus_dev -t -c \
  "SELECT COUNT(*) FROM public.citext_migration_error_log \
   WHERE error_message LIKE '%cannot drop index%';"
# Expected: 0

# 5. Verify report generation works (no TypeError)
ls -la logs/*.md

# 6. Verify exit code reflects actual state
echo $?  # 0 if no errors, 1 if errors
```

## Execution Result (2026-03-25)

**Run ID:** `a7b1e69ee615`

| Check | Result |
|-------|--------|
| Error log | 0 errors (clean run) |
| Views | 20/20 recreated (19 views + 1 MV) |
| Indexes | 16/16 recreated |
| Constraints | 15/15 recreated |
| "cannot drop index" errors | 0 |
| Pipeline exit code | 0 (success) |
| All 172 columns | Already CITEXT (idempotent) |
