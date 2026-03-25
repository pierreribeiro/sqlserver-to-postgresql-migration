# US7 CITEXT Pipeline — Debug Logbook

Cumulative record of bugs found and fixed in the post-migration CITEXT conversion pipeline.

---

## 2026-03-18 — Initial Debug Session (3 bugs)

### Bug 1 (CRASH): YAML Config Uses SQL Server Column Names

**Symptom:** `RuntimeError: psql error (exit 1): ERROR: column "emailaddress" of relation "permissions" does not exist`

**Root Cause:** `config/citext-conversion.yaml` was built from `prompts/columns_citext_candidates.txt` which had SQL Server column names for 3 tables. The YAML also PascalCased two table names (`Permissions`, `Scraper`).

**Fix (3 entries):**
| Table | Before | After |
|-------|--------|-------|
| `Permissions` → `permissions` | `[emailAddress, permission]` | `[email_address, permission]` |
| `Scraper` → `scraper` | `[Active, DocumentID, ...]` (12 PascalCase cols) | `[active, document_id, ...]` (12 snake_case cols) |
| `tmp_messy_links` | `desitnation_name` (typo) | `destination_name` |

**Files:** `config/citext-conversion.yaml`, `prompts/columns_citext_candidates.txt`

---

### Bug 2: `.env` File Never Loaded

**Symptom:** `LOG_DIR` from `.env` is never read. DB connection only works if PG* vars are exported in the shell.

**Root Cause:** `load_db_config()` in `lib/db.py` only calls `load_dotenv(env_file)` when `env_file` is explicitly passed. No caller ever passes it.

**Fix:**
1. Added `load_dotenv()` at module level in `lib/db.py` (auto-discovers `.env`)
2. Changed `--log-dir` default in all 8 phase scripts to `os.environ.get("LOG_DIR", "./logs")`

**Files:** `lib/db.py`, `run_all.py`, `alter_columns.py`, `preflight_check.py`, `drop_dependents.py`, `alter_cache_tables.py`, `recreate_dependents.py`, `validate_conversion.py`, `rollback_citext.py`

---

### Bug 3 (LATENT): Manifest Overwritten Each Phase

**Symptom:** Each phase runner calls `Manifest(path).create()` which always overwrites the file with empty data. Previous phases' records are lost.

**Root Cause:** `create()` unconditionally writes a fresh manifest, wiping data from prior phases.

**Fix:** Changed to load-or-create pattern in `alter_columns.py`, `drop_dependents.py`, `preflight_check.py`:
```python
manifest = Manifest(manifest_path)
if Path(manifest_path).exists():
    manifest.load()
else:
    manifest.create()
```

**Files:** `alter_columns.py`, `drop_dependents.py`, `preflight_check.py`

---

---

## 2026-03-18 — Debug Round 2 (3 more bugs)

### Bug 4 (CRASH): Phase 1 Never Drops Views or Indexes

**Symptom:** `ERROR: cannot alter type of a column used by a view or rule` — Phase 2a ALTER fails because 20 views and 8+ indexes still reference target columns.

**Root Cause:** `run_drop_dependents()` in `drop_dependents.py` was stubbed out — only dropped FK constraints, never views or indexes.

**Fix:**
1. Added imports: `get_all_target_columns`, `discover_dependent_views`, `discover_indexes`, `_get_view_ddl` helper
2. Replaced stub with full implementation:
   - Discover all dependent views across all target tables (dedup by name)
   - Capture DDL via `pg_get_viewdef()` BEFORE dropping
   - Drop MVs first, then regular views (CASCADE handles transitive deps)
   - Discover and drop indexes on target columns
   - All DDL saved to manifest via `record_dropped()` for Phase 3 recreation

**Files:** `drop_dependents.py`

---

### Bug 5 (LATENT): `manifest.create()` Still Wipes Data in 3 More Scripts

**Symptom:** Same as Bug 3 — `manifest.create()` overwrites manifest, losing data from prior phases.

**Root Cause:** Bug 3 fix missed 3 files: `alter_cache_tables.py`, `recreate_dependents.py`, `validate_conversion.py`.

**Fix:** Applied same load-or-create pattern + added `from pathlib import Path` where missing:
```python
manifest = Manifest(manifest_path)
if Path(manifest_path).exists():
    manifest.load()
else:
    manifest.create()
```

**Files:** `alter_cache_tables.py`, `recreate_dependents.py`, `validate_conversion.py`

---

### Bug 6 (CRASH): `run_all.py` Passes Wrong Args to `run_recreate_dependents`

**Symptom:** `TypeError: got an unexpected keyword argument 'config'` — would crash when Phase 3 runs.

**Root Cause:** `run_all.py` called `run_recreate_dependents(config=..., manifest_path=..., ...)` but the original signature expected `dependents: dict` as the first positional arg.

**Fix:** Refactored `run_recreate_dependents` signature to accept `config` (for runner consistency) and load dependents from manifest internally — same logic its own `main()` already used. Removed duplicate reconstruction code from `main()`.

**Files:** `recreate_dependents.py`

---

---

## 2026-03-18 — Debug Round 3 (3 more bugs)

### Bug 7 (CRASH): Interleaved DDL-Capture + DROP with CASCADE

**Symptom:** `RuntimeError: relation "perseus.combined_field_map_display_type" does not exist` — Phase 1 tries to capture DDL for a view that was already destroyed by CASCADE during a prior DROP.

**Root Cause (3 layers):**
1. **Interleaved capture+drop:** DDL captured and object dropped in the same loop iteration. CASCADE silently destroys transitive dependents before their DDL is captured.
2. **Flat dependency query:** `discover_dependent_views()` only found direct dependents. Transitive chains (View C → View B → Table X) were never discovered.
3. **No pre-mutation backup:** If the script crashes after drops, DDL has no persistent backup beyond the JSON manifest (which can be deleted).

**Fix (3 parts):**

**Part A — Recursive view discovery:** New `discover_all_dependent_views()` in `preflight_check.py` uses a recursive CTE via `pg_depend`/`pg_rewrite` to find the complete dependency tree with depth levels. Depth enables: drop order (highest depth first = leaves → root) and recreate order (lowest depth first = root → leaves).

**Part B — Permanent backup table:** New `lib/backup.py` module creates `public.citext_migration_backup` table in PostgreSQL. Survives script crashes, manifest deletion; queryable via psql. Each run gets a unique `run_id`. Functions: `ensure_backup_table()`, `snapshot_object()`, `get_snapshot()`, `mark_dropped()`, `mark_recreated()`, `get_latest_backup_for_object()` (fallback to prior runs).

**Part C — Two-pass architecture:** `run_drop_dependents()` refactored into:
- Pass 1 (Snapshot): Discovers ALL deps recursively, captures ALL DDL into backup table + manifest. Zero mutations.
- Pass 2 (Drop): Reads from backup table, drops in depth order (deepest first). Each DROP wrapped in try/except for idempotency.

**Edge cases handled:** CASCADE chain prevention (depth-ordered drops), view already gone (fallback to prior backup), crash mid-snapshot (idempotent inserts via ON CONFLICT), manifest deleted (backup table is authoritative), run_id persistence across restarts.

**Files:** `preflight_check.py`, `lib/backup.py` (NEW), `drop_dependents.py`, `recreate_dependents.py`

---

### Bug 8 (LATENT): No CITEXT Idempotency Check in ALTER Phases

**Symptom:** Re-running Phase 2a/2b after a crash would ALTER columns that are already CITEXT — wasteful, masks real issues in logs.

**Root Cause:** `alter_table_columns_with_resume()` checked manifest but not the actual DB column type. Manifest could be out of sync with DB state.

**Fix:** Added DB-level type check via `verify_column_type()` before every ALTER:
- `alter_columns.py` — regular columns + FK groups: checks each column, logs warning + updates manifest if already CITEXT
- `alter_cache_tables.py` — cache tables: new `_is_already_citext()` helper, same skip-and-warn pattern
- FK groups: filters already-CITEXT columns, only remaining go into transactional ALTER; empty groups guarded

**Files:** `alter_columns.py`, `alter_cache_tables.py`

---

### Bug 9 (LATENT): FK Constraints Store DROP DDL Instead of CREATE DDL

**Symptom:** Phase 3's `recreate_fk_constraints()` executes `c["ddl"]` — which contained the DROP statement from Phase 1 (e.g., `ALTER TABLE ... DROP CONSTRAINT ...`), not CREATE. Would re-drop instead of recreating.

**Root Cause:** `drop_dependents.py` line 200-206 stored `drop_constraint_sql()` output as "ddl" in the manifest. Additionally, constraint names were guessed as `fk_{table}_{column}` — may not match actual DB names.

**Fix:** In Pass 1 of the two-pass architecture:
1. Discover ACTUAL constraint names from `pg_constraint` (not guessed)
2. Capture CREATE DDL via `pg_get_constraintdef()` → `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ...`
3. Phase 3 now executes CREATE DDL directly to recreate constraints

**Files:** `drop_dependents.py`, `recreate_dependents.py`

---

## 2026-03-19 — Debug Round 4 (Bug 10 + Resilience)

### Bug 10 (CRASH): Phantom Columns Crash Pipeline on ALTER

**Symptom:** `RuntimeError: psql error (exit 1): ERROR: column "X" of relation "Y" does not exist` — if a column defined in `citext-conversion.yaml` doesn't physically exist in the DB, `verify_column_type()` returns False (empty result ≠ "citext"), the ALTER proceeds, PostgreSQL returns the error, and the unhandled RuntimeError kills the entire pipeline.

**Root Cause:** No validation of column existence before ALTER. The YAML config is taken as truth without verifying against `information_schema.columns`.

**Fix:** New `validate_columns_exist()` function in `preflight_check.py` performs a single batch query against `information_schema.columns` for all 172 target columns. Phantom columns are removed from YAML via `purge_phantom_columns()` in `lib/dependency.py`, and `RunAll.run()` reloads the cleaned config before phases 1-4 run.

**Safety valve (D5):** If >50% of columns appear phantom, abort with FATAL — likely wrong schema/database.

**FK group integrity (D3):** If ANY column in an FK group is phantom, the ENTIRE group is removed (FK columns must convert together or not at all).

**Files:** `preflight_check.py`, `lib/dependency.py`, `run_all.py`

---

### Resilience: Permanent Error Log Table

**Symptom:** No persistent audit trail of errors. If the pipeline crashes, the only record is in volatile console output or log files that may not be checked.

**Fix:** New `lib/error_log.py` module creates `public.citext_migration_error_log` table in PostgreSQL. Functions:
- `ensure_error_log_table()` — CREATE IF NOT EXISTS, called once at top of `RunAll.run()`
- `log_error()` — INSERT + Python logger with double try/except (never crashes itself)
- `get_error_summary()` — GROUP BY phase, severity, COUNT for end-of-run reporting

**Files:** `lib/error_log.py` (NEW)

---

### Resilience: `execute_sql_safe()` — Non-Throwing SQL Execution

**Symptom:** Virtually zero `execute_sql()` calls had try/except. Any psql error would raise `RuntimeError` and crash the pipeline.

**Fix:** New `execute_sql_safe()` in `lib/db.py` wraps `execute_sql()`, returns `(success, stdout, error_or_None)` tuple. Never raises. If `run_id` and `phase` are provided, automatically logs to error log table via lazy import (breaks circular dependency with `lib/error_log.py`).

All phase scripts updated to use `execute_sql_safe()` for non-critical operations:
- `alter_columns.py` — ALTER calls, FK group transactions
- `alter_cache_tables.py` — ALTER calls
- `drop_dependents.py` — FK DDL capture gap
- `recreate_dependents.py` — Index, view, MV, FK recreation
- `validate_conversion.py` — Column type validation queries

**Pattern:** Critical operations (preflight, infrastructure setup) still use `execute_sql()` directly and are wrapped in try/except at the orchestrator level. Non-critical per-object operations use `execute_sql_safe()` to log-and-continue.

**Files:** `lib/db.py`, `alter_columns.py`, `alter_cache_tables.py`, `drop_dependents.py`, `recreate_dependents.py`, `validate_conversion.py`

---

### Resilience: `run_id` Threading + Phase Wrapping

**Symptom:** No correlation between errors across phases. No way to query "what went wrong in this run?"

**Fix:** `RunAll` now generates a `run_id` (reused on `--resume`), passes it to all phase runners. Each phase is wrapped in try/except at the orchestrator level — a phase FATAL logs to error table and sets `result["success"] = False`, but the pipeline continues to subsequent phases where possible. Error summary is appended to the final result.

**Files:** `run_all.py`, all phase scripts (new `run_id` parameter)

---

### Other Changes

- `requirements.txt` — Added `ruamel.yaml>=0.18.0` for comment-preserving YAML round-trip
- `verify_column_type()` in `alter_columns.py` — now wrapped in try/except, returns False on error (assume not converted)
- `_is_already_citext()` in `alter_cache_tables.py` — same pattern, returns False on error

---

## 2026-03-25 — Debug Round 5 (4 bugs)

### Bug 11 (P2): Spurious DROP INDEX Errors on Constraint-Backing Indexes

**Symptom:** 22 errors like `cannot drop index uq_coa_name because constraint uq_coa_name on table coa requires it` during Phase 1.

**Root Cause:** `discover_indexes()` finds ALL indexes on target columns, including those backing UNIQUE/PK constraints. `DROP INDEX` fails on these because PostgreSQL requires `DROP CONSTRAINT` instead. But these don't need dropping at all — PostgreSQL automatically rebuilds constraint-backing indexes during `ALTER COLUMN TYPE`.

**Fix:** Added filter to `discover_indexes()` query:
```sql
AND NOT EXISTS (SELECT 1 FROM pg_constraint pc WHERE pc.conindid = i.oid)
```

**Files:** `preflight_check.py`

---

### Bug 12 (P0 CRITICAL): `get_snapshot()` Can't Parse Multi-Line DDL

**Symptom:** ALL 20 views silently dropped from backup table reads. `_drop_from_snapshot()` gets empty view list → never drops views → Phase 2a/2b ALTERs fail with 29+5 errors.

**Root Cause (2 layers):**
1. `pg_get_viewdef()` returns multi-line DDL. `snapshot_object()` stores it as-is. `get_snapshot()` reads via `psql -t -A` and parses with `splitlines()` + `split("|")`. Multi-line DDL becomes multiple output lines — first line has only 5 fields (not 6), so `len(parts) >= 6` fails silently.
2. 7/20 views have `||` (SQL concatenation) in DDL, which also breaks `split("|")`.

**Fix (2 parts):**
1. **`snapshot_object()`** — normalize DDL to single-line before storing: `" ".join(ddl.split())`
2. **`get_snapshot()`** — parse with `rpartition("|")` to split status (always last), then `split("|", 4)` for first 5 fields (DDL in field 5 may contain pipes)

**Files:** `lib/backup.py`

---

### Bug 13 (P1): `run_generate_report()` Wrong Kwarg

**Symptom:** `TypeError` on Phase 5 — `run_generate_report()` received unexpected keyword argument `log_dir`.

**Root Cause:** Call used `log_dir=self.log_dir` but the function signature expects `report_dir`.

**Fix:** Changed `log_dir=self.log_dir` → `report_dir=self.log_dir`.

**Files:** `run_all.py`

---

### Bug 14 (P1): Pipeline Reports Success Despite 34 Errors

**Symptom:** Final message says "All phases completed successfully" even with 34 errors logged.

**Root Cause:** `result["success"]` only set to `False` on phase-level exceptions (FATAL). Per-object errors logged via `execute_sql_safe()` don't bubble up to set the success flag.

**Fix:** After `get_error_summary()`, iterate phases and check for ERROR/FATAL counts:
```python
for phase_data in summary.values():
    if isinstance(phase_data, dict):
        if phase_data.get("ERROR", 0) > 0 or phase_data.get("FATAL", 0) > 0:
            result["success"] = False
            break
```

**Files:** `run_all.py`

---

## Cleanup

- Deleted `scripts/post-migration/manifest.json` for clean re-run after all fixes.
