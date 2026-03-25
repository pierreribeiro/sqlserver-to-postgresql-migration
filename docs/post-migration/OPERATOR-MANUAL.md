# US7: CITEXT Column Conversion -- Operator Execution Manual

> **Scope:** Convert 172 VARCHAR columns to CITEXT across ~65 PostgreSQL tables
> **Target databases:** perseus_dev | perseus_staging | perseus_prod
> **Estimated duration:** 3-7 hours (dominated by cache table m_upstream)
> **Last updated:** 2026-03-19

---

## Table of Contents

1. [Pre-requisites](#1-pre-requisites)
2. [Setup](#2-setup)
3. [Pre-execution Checklist](#3-pre-execution-checklist)
4. [Execution Commands](#4-execution-commands)
5. [Post-execution Checklist](#5-post-execution-checklist)
6. [Troubleshooting](#6-troubleshooting)
7. [Appendix](#7-appendix)

---

## 1. Pre-requisites

### Operator Workstation

| Requirement | Minimum Version | Verification Command |
|---|---|---|
| Python | 3.10+ | `python3 --version` |
| pip | latest | `pip --version` |
| psql (PostgreSQL client) | 14+ | `psql --version` |
| Network access | Port 5432 (or configured) | `pg_isready -h <host> -p 5432` |

### Database Privileges

The executing database role **must** have the following privileges on the target schema:

- `ALTER` on all target tables
- `DROP` on views, indexes, and constraints
- `CREATE` on views, indexes, and constraints
- `CREATE TABLE` on `public` schema (for infrastructure tables)
- `USAGE` on the `citext` extension
- Superuser or equivalent is recommended for the maintenance window

Verify with:

```bash
psql -h <host> -U <user> -d perseus_dev -c "SELECT current_setting('is_superuser');"
# Expected: 't' (or verify ALTER privileges on target schema)
```

### Python Dependencies

```bash
cd scripts/post-migration/
pip install -r requirements.txt
```

The `requirements.txt` installs:

| Package | Purpose |
|---|---|
| `python-dotenv` (>=1.0.0) | Load database credentials from `.env` file |
| `pyyaml` (>=6.0) | Parse `citext-conversion.yaml` config |
| `ruamel.yaml` (>=0.18.0) | Comment-preserving YAML round-trip (for phantom column purge) |
| `rich` (>=13.0) | Formatted console output and progress bars |

---

## 2. Setup

### 2.1 Environment File

Copy the example environment file and fill in your database credentials:

```bash
cd scripts/post-migration/
cp .env.example .env
```

Edit `.env` with your credentials:

```dotenv
PGHOST=your-database-host.example.com
PGPORT=5432
PGDATABASE=perseus_dev
PGUSER=your_username
PGPASSWORD=your_password
PGSCHEMA=perseus
```

> **Security:** The `.env` file is gitignored. Never commit credentials to version control.

### 2.2 Directory Structure

```
scripts/post-migration/
├── 00-preflight-check.py       # Phase 0 CLI entry point (thin wrapper)
├── 01-drop-dependents.py       # Phase 1 CLI entry point (thin wrapper)
├── 02-alter-columns.py         # Phase 2a CLI entry point (thin wrapper)
├── 02b-alter-cache-tables.py   # Phase 2b CLI entry point (thin wrapper)
├── 03-recreate-dependents.py   # Phase 3 CLI entry point (thin wrapper)
├── 04-validate-conversion.py   # Phase 4 CLI entry point (thin wrapper)
├── 05-generate-report.py       # Phase 5 CLI entry point (thin wrapper)
├── run-all.py                  # Orchestrator CLI entry point (thin wrapper)
├── rollback-citext.py          # Full rollback CLI entry point (thin wrapper)
│
├── preflight_check.py          # Phase 0 logic — validation + column existence check
├── drop_dependents.py          # Phase 1 logic — two-pass snapshot + drop
├── alter_columns.py            # Phase 2a logic — ALTER regular columns + FK groups
├── alter_cache_tables.py       # Phase 2b logic — ALTER cache table columns
├── recreate_dependents.py      # Phase 3 logic — recreate indexes, FKs, views
├── validate_conversion.py      # Phase 4 logic — validate column types
├── generate_report.py          # Phase 5 logic — generate summary report
├── run_all.py                  # Orchestrator logic — RunAll class
├── rollback_citext.py          # Rollback logic
│
├── config/
│   └── citext-conversion.yaml  # Column targets and grouping config
├── lib/
│   ├── backup.py               # Persistent backup table (citext_migration_backup)
│   ├── db.py                   # Database connection, execute_sql, execute_sql_safe
│   ├── dependency.py           # Config loader, dependency discovery, phantom purge
│   ├── error_log.py            # Persistent error log table (citext_migration_error_log)
│   ├── logger.py               # Logging setup (dual: console + file)
│   ├── manifest.py             # Checkpoint/resume state management
│   └── sql_templates.py        # SQL generation templates
├── requirements.txt            # Python dependencies
├── logs/                       # Created at runtime — log files per phase
└── manifest.json               # Created at runtime — checkpoint state
```

**Naming convention:** `XX-kebab-name.py` files are thin CLI wrappers (3 lines each) that import `main()` from the corresponding `snake_name.py` module. The operator runs the kebab-named files; the logic lives in the snake-named files.

### 2.3 Configuration File

The file `config/citext-conversion.yaml` defines:

- **`fk_groups`** -- Columns linked by foreign keys that must be converted in a single transaction (e.g., the 6 UID columns across `goo`, `fatsmurf`, `material_transition`, `transition_material`).
- **`cache_tables`** -- Large cache tables (`m_upstream_dirty_leaves`, `m_downstream`, `m_upstream`) converted last in Phase 2b.
- **`independent_columns`** -- All remaining columns (~160) grouped by table, with no FK dependencies.
- **`large_tables_order`** -- Execution order for tables with 500K+ rows, sorted by ascending size.

You should not need to modify this file unless the target column list changes. The pipeline auto-cleans phantom columns (see Section 4.7).

### 2.4 Infrastructure Tables

The pipeline creates two persistent tables in PostgreSQL automatically on first run:

| Table | Schema | Purpose |
|---|---|---|
| `citext_migration_backup` | `public` | DDL backup of dropped objects (views, indexes, FKs). Survives script crashes. |
| `citext_migration_error_log` | `public` | Permanent audit trail of all errors, warnings, and fatals across runs. |

These tables are **created automatically** — no manual DDL is needed. They persist between runs for audit.

---

## 3. Pre-execution Checklist

Complete every item before starting execution. All commands assume your working directory is `scripts/post-migration/`.

### Connectivity and Pre-flight

- [ ] **Verify database connectivity:**
  ```bash
  python 00-preflight-check.py --test-connection
  ```
  Expected output: connection success message with database version and current user.

- [ ] **Run full pre-flight analysis:**
  ```bash
  python 00-preflight-check.py --config config/citext-conversion.yaml
  ```
  This performs: citext extension check, permission validation, case-variant duplicate scan, disk space estimation, and dependency discovery. It produces `manifest.json` on success.

- [ ] **Review pre-flight output** -- Confirm zero BLOCKER findings. Any case-variant duplicates must be resolved manually before proceeding.

### Infrastructure

- [ ] **Confirm citext extension is installed on the target database:**
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c "CREATE EXTENSION IF NOT EXISTS citext;"
  ```

- [ ] **Verify disk space** -- At least 240 GB free (1.5x the size of `m_upstream` at 157 GB):
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c "SELECT pg_size_pretty(pg_database_size(current_database()));"
  ```
  Check available disk on the database server filesystem.

- [ ] **Confirm no stale manifest** -- If `manifest.json` exists from a previous run, either delete it (fresh start) or keep it (resume scenario):
  ```bash
  ls -la manifest.json 2>/dev/null && echo "EXISTS — delete for fresh run or keep for resume" || echo "OK — no stale manifest"
  ```

### Operations

- [ ] **Schedule maintenance window** -- Minimum 8 hours reserved (includes buffer for m_upstream rewrite).

- [ ] **Notify users of planned downtime** -- Send maintenance notification per your organization's change management process.

- [ ] **Drain application connections** -- Ensure no active application queries against target tables:
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c \
    "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND state = 'active' AND pid != pg_backend_pid();"
  ```

- [ ] **Confirm replication lag is zero** (if replicas exist):
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c \
    "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;"
  ```

- [ ] **Take database backup:**
  ```bash
  pg_dump -Fc -h <host> -U <user> -d perseus_dev > backup_pre_citext_$(date +%Y%m%d_%H%M%S).dump
  ```
  Verify the backup completed successfully:
  ```bash
  pg_restore --list backup_pre_citext_*.dump | head -20
  ```

- [ ] **Open monitoring dashboards** -- Have `pg_stat_activity`, disk usage, and lock monitoring visible during the window.

- [ ] **DBA on-call confirmed** -- Named DBA available for the duration of the maintenance window.

---

## 4. Execution Commands

All commands are run from `scripts/post-migration/`.

### 4.1 Full Automated Run

The recommended approach for a clean first execution:

```bash
python run-all.py --config config/citext-conversion.yaml
```

This runs all six phases (0 through 5) sequentially. Key behaviors:

- Generates a unique **`run_id`** for correlating errors across all phases
- Creates infrastructure tables (`citext_migration_backup`, `citext_migration_error_log`) automatically
- **Validates all YAML columns** against the database before ALTER — phantom columns are auto-purged from the YAML
- Each phase writes checkpoints to `manifest.json`
- Non-critical errors are **logged to the error log table and continued** — the pipeline does not crash on individual column failures
- At the end, prints an **error summary** grouped by phase and severity

### 4.2 Dry Run

Preview all SQL that would be executed without making any changes:

```bash
python run-all.py --config config/citext-conversion.yaml --dry-run
```

Review the output to confirm the plan matches expectations. No database modifications are made. Infrastructure tables and column validation are skipped in dry-run mode.

### 4.3 Phase-by-Phase Manual Control

For greater control, run each phase individually. This is recommended for the first deployment to a new environment.

```bash
# Phase 0: Pre-flight (read-only, generates manifest.json)
python 00-preflight-check.py --config config/citext-conversion.yaml

# Phase 1: Drop dependent objects (views, FKs, indexes)
python 01-drop-dependents.py

# Phase 2a: ALTER regular table columns to CITEXT
python 02-alter-columns.py

# Phase 2b: ALTER cache table columns to CITEXT (long-running)
python 02b-alter-cache-tables.py

# Phase 3: Recreate dependent objects (indexes, FKs, views)
python 03-recreate-dependents.py

# Phase 4: Validate all conversions
python 04-validate-conversion.py

# Phase 5: Generate summary report
python 05-generate-report.py
```

Inspect `manifest.json` and `logs/` between phases to confirm each completed successfully.

> **Note:** When running phases individually, `run_id` is not automatically threaded. The orchestrator (`run-all.py`) provides full run_id correlation and error log table integration.

### 4.4 Resume After Interruption

If a phase fails or is interrupted (e.g., network drop, disk full, manual abort):

```bash
python run-all.py --config config/citext-conversion.yaml --resume
```

The `--resume` flag reads `manifest.json` and:
- Skips phases already marked `complete`
- Retries columns/objects marked `pending` or `failed`
- Picks up exactly where the last successful checkpoint left off
- Reuses the `run_id` from the prior run (errors stay correlated)

You can also resume a specific phase by re-running its individual script. Completed items within that phase are skipped automatically.

### 4.5 Full Rollback

If the conversion must be completely undone (e.g., application incompatibility discovered):

```bash
python rollback-citext.py --manifest manifest.json
```

Preview rollback actions without executing:

```bash
python rollback-citext.py --manifest manifest.json --dry-run
```

The rollback script:
1. Reads `manifest.json` for original column types and saved DDL
2. Reverts all CITEXT columns back to their original VARCHAR types
3. Drops recreated objects and restores originals from manifest DDL
4. Returns the database to its pre-US7 state

### 4.6 Monitoring During Phase 2b (Cache Tables)

Phase 2b is the longest-running phase. Monitor the `m_upstream` ALTER progress with:

```sql
-- Check active ALTER operation
SELECT pid, state, wait_event_type, wait_event,
       now() - query_start AS duration, query
FROM pg_stat_activity
WHERE query LIKE '%m_upstream%';

-- Check for lock contention
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_query
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
WHERE NOT blocked_locks.granted;

-- Monitor disk usage during rewrite
SELECT pg_size_pretty(pg_total_relation_size('perseus.m_upstream')) AS table_size;
```

### 4.7 Phantom Column Handling

The orchestrator automatically detects "phantom columns" — columns defined in `citext-conversion.yaml` but absent from the database:

1. After preflight confirms DB connectivity, all 172 columns are batch-checked against `information_schema.columns`
2. Phantom columns are logged as `WARNING` to the error log table
3. The YAML config is backed up (`.bak.TIMESTAMP`) and rewritten without phantom entries
4. Config is reloaded in memory — phases 1-4 run with the cleaned config

**Safety valve:** If >50% of columns appear phantom, the pipeline **ABORTs** with a FATAL error. This indicates a misconfiguration (wrong schema or database), not genuine phantom columns.

**FK group rule:** If ANY column in an FK group is phantom, the ENTIRE FK group is removed. FK columns must convert together or not at all.

To inspect phantom column activity after a run:

```bash
psql -d perseus_dev -c \
  "SELECT table_name, column_name FROM public.citext_migration_error_log \
   WHERE operation = 'PREFLIGHT' AND severity = 'WARNING' ORDER BY table_name;"
```

### 4.8 Error Log Inspection

All errors across all phases are persisted in `public.citext_migration_error_log`:

```bash
# Summary by phase and severity
psql -d perseus_dev -c \
  "SELECT phase, severity, COUNT(*) FROM public.citext_migration_error_log \
   GROUP BY phase, severity ORDER BY phase;"

# Errors for the latest run
psql -d perseus_dev -c \
  "SELECT phase, severity, table_name, column_name, error_message \
   FROM public.citext_migration_error_log \
   WHERE run_id = (SELECT DISTINCT run_id FROM public.citext_migration_error_log ORDER BY run_id DESC LIMIT 1) \
   ORDER BY occurred_at;"

# Count by run_id (verify idempotency — re-runs should not add new errors)
psql -d perseus_dev -c \
  "SELECT run_id, COUNT(*) FROM public.citext_migration_error_log GROUP BY run_id;"
```

---

## 5. Post-execution Checklist

- [ ] **Review Phase 5 report** -- Confirm all 172 columns show `udt_name = 'citext'` in the generated report.

- [ ] **Review error log** -- Check for any unresolved errors:
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c \
    "SELECT COUNT(*) AS errors FROM public.citext_migration_error_log WHERE severity = 'ERROR' AND resolved = FALSE;"
  ```
  Expected: 0 errors. If errors exist, investigate each one.

- [ ] **Verify application connectivity** -- Restart application services and confirm they connect successfully to the database.

- [ ] **Spot-check views return data:**
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c "SELECT * FROM perseus.translated LIMIT 5;"
  ```
  Repeat for 4-5 additional views.

- [ ] **Verify FK constraints are valid:**
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c \
    "SELECT conname, convalidated FROM pg_constraint WHERE contype = 'f' AND connamespace = 'perseus'::regnamespace;"
  ```
  All constraints should show `convalidated = true`.

- [ ] **Test case-insensitive behavior:**
  ```bash
  psql -h <host> -U <user> -d perseus_dev -c \
    "SELECT uid FROM perseus.goo WHERE uid = 'ABC' LIMIT 1;"
  ```
  This should match rows regardless of original case (e.g., stored as `'abc'` or `'Abc'`).

- [ ] **Run application smoke tests** -- Execute core application workflows against the converted database.

- [ ] **Capture performance baselines** -- Run key queries and compare to pre-conversion baselines. Confirm results are within +/- 20%.

- [ ] **Archive manifest:**
  ```bash
  cp manifest.json docs/post-migration/manifest_$(date +%Y%m%d_%H%M%S).json
  ```

- [ ] **Retain pre-conversion backup** -- Keep the `pg_dump` backup for a minimum of 30 days.

- [ ] **Monitor for 24 hours** -- Watch for unusual lock waits, CPU spikes, replication lag, or application errors.

- [ ] **Notify users maintenance is complete** -- Send all-clear notification.

---

## 6. Troubleshooting

### 6.1 Common Errors and Solutions

| Error | Cause | Solution |
|---|---|---|
| `ERROR: type "citext" does not exist` | citext extension not installed | Run `CREATE EXTENSION IF NOT EXISTS citext;` on the target database |
| `ERROR: permission denied for table ...` | Insufficient privileges | Grant `ALTER` on target tables or use a superuser role |
| `ERROR: cannot alter column ... because a view depends on it` | Phase 1 did not drop all dependents | Re-run `01-drop-dependents.py`; check manifest for missed objects |
| `ERROR: column "X" of relation "Y" does not exist` | Phantom column in YAML config | Pipeline auto-purges phantoms on next run. Check error_log for details. |
| `ERROR: could not extend file ...` | Disk full during table rewrite | Free disk space, then `--resume` |
| `ERROR: deadlock detected` | Concurrent DDL or long-running queries | Drain application connections, retry the phase |
| `ERROR: duplicate key value violates unique constraint` | Case-variant duplicates exist | Run pre-flight to identify duplicates; resolve them manually before retrying |
| `TIMEOUT` on Phase 2b | m_upstream rewrite exceeds connection timeout | Increase `statement_timeout` to 0 for the session: `SET statement_timeout = 0;` |
| `manifest.json not found` | Phase 0 was not run or manifest was deleted | Re-run `00-preflight-check.py` to regenerate. Backup table in PostgreSQL still has DDL. |
| `SAFETY VALVE: >50% phantom` | Wrong schema or database in `.env` | Verify `PGDATABASE`, `PGSCHEMA` in `.env` match the target environment |
| FK group FATAL in error log | Phantom column in FK chain | Entire FK group removed from YAML. Investigate why the column is missing. |

### 6.2 How to Interpret Log Files

Logs are written to `scripts/post-migration/logs/` with one file per phase per run:

```
logs/
├── 00-preflight-check-20260319-141500.log
├── 01-drop-dependents-20260319-141502.log
├── 02-alter-columns-20260319-141510.log
├── 02b-alter-cache-tables-20260319-141520.log
├── 03-recreate-dependents-20260319-142000.log
├── 04-validate-conversion-20260319-142010.log
├── 05-generate-report-20260319-142015.log
├── run-all-20260319-141500.log      # Orchestrator log
└── rollback-citext-*.log            # Only if rollback was executed
```

Each log entry includes a timestamp with milliseconds, level (INFO/WARNING/ERROR/SQL/OK/CHECKPOINT/ABORT), and message. Search for `ERROR` entries to diagnose failures:

```bash
grep -i ERROR logs/*.log
```

For deeper investigation, query the persistent error log table — it has structured fields (phase, table, column, SQL attempted):

```bash
psql -d perseus_dev -c \
  "SELECT phase, table_name, column_name, operation, error_message \
   FROM public.citext_migration_error_log ORDER BY occurred_at DESC LIMIT 20;"
```

### 6.3 When to Use Rollback vs Resume

| Situation | Action | Command |
|---|---|---|
| Phase failed partway; root cause is fixable (e.g., disk space, lock timeout) | **Resume** | `python run-all.py --resume` |
| Phase failed; you already fixed the underlying issue | **Resume** | Re-run the individual phase script |
| Individual column ALTERs failed but most succeeded | **Investigate** | Check error log table; re-run `--resume` after fixing |
| All phases completed but validation shows failures | **Investigate first** | Review Phase 4 output; fix forward if possible |
| Application is broken after conversion; need to undo everything | **Full rollback** | `python rollback-citext.py --manifest manifest.json` |
| Rollback itself fails | **Restore from backup** | `pg_restore -Fc -d perseus_dev backup_pre_citext_*.dump` |

**Decision tree:**

1. Can the issue be fixed without reverting columns? -> **Resume** after fixing.
2. Is the issue limited to recreated objects (views, indexes)? -> Re-run Phase 3 only.
3. Must column types be reverted? -> **Full rollback** via `rollback-citext.py`.
4. Is the manifest corrupted or unavailable? -> Check `citext_migration_backup` table first, then **restore from backup** if needed.

### 6.4 Resilience Behavior

The pipeline is designed to **log errors and continue** rather than crash:

- **Individual column ALTER fails:** Error is logged to `citext_migration_error_log`, column is skipped, next column proceeds
- **FK group ALTER fails:** Entire group transaction rolls back, all group columns logged as failed, next group proceeds
- **Index/view/MV recreation fails:** Error logged, object skipped, next object proceeds
- **Phase-level crash (unexpected exception):** Logged as FATAL to error log, `result.success = False`, but subsequent phases still run
- **DB connection lost during error logging:** Falls back to Python file logger only — `log_error()` never crashes itself

The `errors_count` field in each phase's report shows how many items failed. Check the error log table for details.

### 6.5 Contact Information

| Role | Contact | When |
|---|---|---|
| Project Lead / Senior DBA | Pierre Ribeiro | Architecture decisions, escalation |
| On-call DBA | Per rotation schedule | During maintenance window execution |
| Application team | Per team channel | Post-conversion smoke test coordination |

---

## 7. Appendix

### 7.1 Script File Reference

| Script | Phase | Purpose | Destructive | Estimated Duration |
|---|---|---|---|---|
| `00-preflight-check.py` | 0 | Verify prerequisites, discover dependencies, generate manifest | No | < 1 min |
| `01-drop-dependents.py` | 1 | Two-pass: snapshot DDL to backup table, then drop (depth-ordered) | Yes | 2-5 min |
| `02-alter-columns.py` | 2a | ALTER regular table columns from VARCHAR to CITEXT | Yes | 5-30 min |
| `02b-alter-cache-tables.py` | 2b | ALTER cache table columns (m_upstream_dirty_leaves, m_downstream, m_upstream) | Yes | 2-6 hours |
| `03-recreate-dependents.py` | 3 | Recreate indexes, FK constraints, materialized views, and views | No (additive) | 5-30 min |
| `04-validate-conversion.py` | 4 | Validate all 172 columns, views, indexes, FKs, and case-insensitive behavior | No | 5-10 min |
| `05-generate-report.py` | 5 | Generate summary markdown report with before/after comparison | No | < 1 min |
| `run-all.py` | All | Orchestrator -- runs Phases 0-5 with run_id, error logging, phantom purge | Yes | 3-7 hours |
| `rollback-citext.py` | N/A | Full rollback -- revert all columns and objects to pre-conversion state | Yes | 1-4 hours |

### 7.2 CLI Flags Reference

| Script | Flag | Description |
|---|---|---|
| `00-preflight-check.py` | `--test-connection` | Test database connectivity only (no analysis) |
| `00-preflight-check.py` | `--config PATH` | Path to YAML config file (default: `config/citext-conversion.yaml`) |
| `00-preflight-check.py` | `--dry-run` | Show what would be checked without executing |
| `run-all.py` | `--config PATH` | Path to YAML config file |
| `run-all.py` | `--dry-run` | Preview all SQL without executing |
| `run-all.py` | `--resume` | Skip completed phases, retry pending/failed items, reuse prior run_id |
| `run-all.py` | `--manifest PATH` | Path to manifest.json (default: `./manifest.json`) |
| `run-all.py` | `--log-dir DIR` | Log output directory (default: `$LOG_DIR` or `./logs`) |
| `rollback-citext.py` | `--manifest PATH` | Path to manifest.json (default: `./manifest.json`) |
| `rollback-citext.py` | `--dry-run` | Preview rollback SQL without executing |

### 7.3 Infrastructure Tables

**`public.citext_migration_backup`** — DDL backup (created by `lib/backup.py`)

| Column | Type | Description |
|---|---|---|
| `run_id` | TEXT | Unique pipeline run identifier |
| `phase` | TEXT | Phase that created the backup |
| `object_type` | TEXT | `view`, `materialized_view`, `index`, `constraint` |
| `schema_name` | TEXT | Schema of the object |
| `object_name` | TEXT | Name of the object |
| `depth` | INTEGER | Dependency depth (0 = direct, higher = transitive) |
| `ddl` | TEXT | Full CREATE DDL for recreation |
| `status` | TEXT | `backed_up` → `dropped` → `recreated` |

**`public.citext_migration_error_log`** — Error audit (created by `lib/error_log.py`)

| Column | Type | Description |
|---|---|---|
| `run_id` | TEXT | Pipeline run identifier |
| `phase` | TEXT | Phase where error occurred |
| `severity` | TEXT | `ERROR`, `WARNING`, `FATAL` |
| `table_name` | TEXT | Affected table (if applicable) |
| `column_name` | TEXT | Affected column (if applicable) |
| `object_type` | TEXT | `column`, `index`, `view`, `constraint`, `config`, `fk_group` |
| `operation` | TEXT | `ALTER`, `DROP`, `CREATE`, `VALIDATE`, `PREFLIGHT`, `PURGE_PHANTOM` |
| `sql_attempted` | TEXT | The SQL that failed |
| `error_message` | TEXT | Error description |
| `resolved` | BOOLEAN | Whether the error has been resolved (default: FALSE) |

### 7.4 Phase Execution Order

For the detailed phase flowchart with Mermaid diagrams showing drop order, conversion order, and recreation order, see:

**[`docs/debugging/post-migration/citext-pipeline-flowchart.md`](../debugging/post-migration/citext-pipeline-flowchart.md)**

Summary execution order:

```
Phase 0: Pre-flight Analysis
    │
    ├── Verify connection, citext extension, permissions
    ├── Generate manifest with original column types
    │
    v
Column Validation (in orchestrator, after preflight)
    │
    ├── Batch check all YAML columns against information_schema
    ├── Purge phantom columns from YAML (backup original)
    ├── Reload cleaned config in memory
    │
    v
Phase 1: Drop Dependents (Two-Pass)
    │
    ├── Pass 1: Snapshot all DDL to backup table + manifest (zero mutations)
    ├── Pass 2: Drop depth-ordered (deepest first, no CASCADE chains)
    │
    v
Phase 2a: ALTER Regular Tables (small → large → FK group atomic)
    │
    ├── Individual columns via execute_sql_safe (log + continue on error)
    ├── FK groups in single transaction (all-or-nothing per group)
    │
    v
Phase 2b: ALTER Cache Tables (dirty_leaves → downstream → upstream)
    │
    v
Phase 3: Recreate Dependents (Bottom-Up)
    │
    ├── Indexes (IF NOT EXISTS)
    ├── FK Constraints (from CREATE DDL)
    ├── Materialized Views
    ├── Views (depth ASC, root first)
    │
    v
Phase 4: Validate Conversion (column types, wrap errors)
    │
    v
Phase 5: Generate Report
    │
    v
Error Summary (from citext_migration_error_log)
```

### 7.5 Key File Locations

| File | Location | Purpose |
|---|---|---|
| YAML config | `scripts/post-migration/config/citext-conversion.yaml` | Column targets, FK groups, cache tables |
| YAML backup | `scripts/post-migration/config/citext-conversion.yaml.bak.*` | Auto-created before phantom purge |
| Manifest (runtime) | `scripts/post-migration/manifest.json` | Checkpoint state, saved DDL for rollback |
| Logs (runtime) | `scripts/post-migration/logs/` | Per-phase log files with timestamps |
| Backup table | `public.citext_migration_backup` (in PostgreSQL) | Authoritative DDL source — survives manifest loss |
| Error log table | `public.citext_migration_error_log` (in PostgreSQL) | Permanent error audit trail across runs |
| Pipeline flowchart | `docs/debugging/post-migration/citext-pipeline-flowchart.md` | Mermaid diagrams of all phases |
| Debug logbook | `docs/debugging/post-migration/debug-logbook.md` | Cumulative bug fix history |
| Dependency analysis | `docs/post-migration/citext-dependency-analysis.md` | View and FK dependency chains |
| Table grouping | `docs/post-migration/citext-table-grouping.md` | Table size tiers and grouping rationale |
