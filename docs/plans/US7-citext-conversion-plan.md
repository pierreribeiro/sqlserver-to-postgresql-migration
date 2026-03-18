# US7: VARCHAR to CITEXT Column Conversion — Implementation Plan

## Context

During the Perseus SQL Server to PostgreSQL migration (US3), AWS SCT converted ALL varchar/nvarchar to CITEXT. The team manually reverted most to VARCHAR for performance. Now **172 specific columns across ~65 tables** need to be converted back to CITEXT where case-insensitive comparison is required by the application.

**Critical constraint**: PostgreSQL does NOT allow `ALTER COLUMN TYPE` on columns with active FK constraints, indexes, or view references. All dependents must be dropped first, columns altered, then dependents recreated in correct order.

**Target columns source**: `prompts/columns_citext_candidates.txt` (172 ALTER statements)

**User decisions**:
- Cache tables m_upstream (686M rows) and m_downstream (33.8M rows) **included** — downtime window available
- Strategy: **Direct ALTER** (no TRUNCATE) — sufficient downtime window available
- Cache tables are the **LAST tables** to be converted in the entire process
- **TDD methodology**: tests created FIRST for each script; script only approved when tests pass
- Tests stored in `tests/citext/` subfolder

---

## Scope Summary

| Category | Count | Details |
|----------|-------|---------|
| Target columns | 172 | Across ~65 tables |
| FK constraints to drop/recreate | 4 | VARCHAR-based UID FKs (material lineage) |
| UNIQUE indexes affected | 13+ | goo.uid, fatsmurf.uid, container.uid, name columns |
| Views to drop/recreate | 22 | All views reference target tables |
| Materialized view | 1 | `translated` — explicit `::VARCHAR(50)` casts must be updated |
| Procedures to update | 15 | **DEFERRED** — documentation only (future worktree) |
| Functions to review | TBD | **DEFERRED** — documentation only (future worktree) |
| CHECK constraints | 3 | submission_entry (compatible, no changes) |
| DEFAULT values | 2 | container.scope_id gen_random_uuid() (compatible) |

### Table Volume Groups (from all_perseus_rowcount_table_size.csv)

**Large (>=500K rows) — execution order ascending by size (smallest first, cache tables LAST):**

| Order | Table | Rows | Size | Columns | Group |
|-------|-------|------|------|---------|-------|
| 1 | fatsmurf_reading | 3.8M | 247 MB | name | Regular |
| 2 | robot_log_read | 2M | 259 MB | source_barcode, source_position, value | Regular |
| 3 | robot_log_transfer | 1.7M | 335 MB | 5 columns | Regular |
| 4 | transition_material | 5.2M | 468 MB | material_id, transition_id | FK Group A |
| 5 | container | 4.3M | 724 MB | name, position_name, position_x/y, scope_id, uid | Regular |
| 6 | goo | 5.9M | 880 MB | catalog_label, description, name, uid | FK Group A |
| 7 | material_transition | 9M | 896 MB | material_id, transition_id | FK Group A |
| 8 | fatsmurf | 8M | 1.4 GB | description, name, uid | FK Group A |
| 9 | robot_log | 3.8M | 2.0 GB | file_name, log_text, robot_log_checksum, source | Regular |
| 10 | poll | 16.7M | 2.1 GB | value | Regular |
| 11 | history_value | 46M | 2.7 GB | value | Regular |
| 12 | m_downstream | 33.8M | 6.5 GB | start_point, end_point, path | **Cache (LAST group)** |
| 13 | m_upstream | 686M | 157 GB | start_point, end_point, path | **Cache (VERY LAST)** |

**Note**: All large tables use Direct ALTER. Cache tables (m_downstream, m_upstream) are the absolute last tables to be converted in the entire process. m_upstream_dirty_leaves (0 rows) also included in cache group.

**Small (<500K rows) — near-instant ALTER:**
All remaining ~50 tables (goo_type: 582, manufacturer: 140, perseus_user: 4536, etc.)

---

## FK Dependency Groups (MUST convert together)

**Group A — Material Lineage (P0 CRITICAL):**
```
Parent: goo.uid → Children: material_transition.material_id, transition_material.material_id
Parent: fatsmurf.uid → Children: material_transition.transition_id, transition_material.transition_id
```
These 4 FK constraints have CASCADE DELETE (and 2 have CASCADE UPDATE). All 6 columns MUST be converted in the same transaction.

**All other target columns**: No FK constraints on VARCHAR columns — can be converted independently.

---

## Phase Breakdown (6 Phases + Deferred Documentation)

### Phase 0: Pre-flight Analysis (`00-preflight-check.py`)
1. Verify `citext` extension enabled
2. Verify DB connectivity and permissions (SUPERUSER or ALTER privilege)
3. Parse `citext-conversion.yaml` → load target columns
4. Query `pg_catalog` to discover ALL dependents dynamically:
   - `pg_constraint` → FK constraints on target columns
   - `pg_indexes` → indexes on target columns
   - `pg_depend` + `pg_rewrite` → views/MVs referencing target tables
   - `pg_trigger` → triggers on target tables
   - `pg_proc` → functions/procedures with matching parameter types
5. **Case-variant duplicate check** (BLOCKER if found):
   ```sql
   SELECT column, LOWER(column), COUNT(*)
   FROM table GROUP BY LOWER(column) HAVING COUNT(*) > 1
   ```
   Run on ALL columns with UNIQUE constraints: goo.uid, fatsmurf.uid, container.uid, goo_type.name, etc.
6. **Disk space check**: Estimate space needed for table rewrites (large tables need ~1.5x current size temporarily)
7. Classify tables: small vs large
8. Generate dependency graph (JSON + mermaid for docs)
9. Output: `manifest.json` with all planned operations, original DDL, rollback SQL

**Failure modes addressed:**
- Missing citext extension → ABORT with instructions
- Insufficient permissions → ABORT with required GRANT statements
- Case-variant duplicates found → ABORT with report of duplicates to resolve manually
- Insufficient disk space → WARN with estimate

### Phase 1: Drop Dependent Objects (`01-drop-dependents.py`) — Top-Down

**Order**: Views (highest wave first) → MV → Triggers → FK Constraints → Indexes

```
Wave 3 (drop first): vw_recipe_prep_part, vw_jeremy_runs, vw_tom_*,
                      vw_fermentation_upstream, vw_process_upstream
Wave 2: vw_lot_edge, vw_lot_path, vw_lot, hermes_run, vw_recipe_prep
Wave 1: upstream, downstream, material_transition_material
Wave 0: translated (MV — CASCADE drops its indexes/triggers automatically)
Then:   FK constraints (4), Indexes on target columns, Triggers on target tables
```

- Each DROP statement logged with timestamp
- DDL of each dropped object saved to manifest for rollback/recreation
- **Checkpoint**: manifest updated after EACH drop — enables resume from any point
- Uses `IF EXISTS` on all drops to be idempotent (safe re-run)

**Failure modes addressed:**
- View doesn't exist → `IF EXISTS` handles gracefully
- Permission denied → log error, ABORT with guidance
- Network interruption → resume reads manifest, skips already-dropped objects

### Phase 2a: ALTER COLUMN TYPE — Regular Tables (`02-alter-columns.py`)

For each FK group and independent column:
```sql
BEGIN;
  ALTER TABLE perseus.{table} ALTER COLUMN {column} TYPE citext;
  -- verify: SELECT udt_name FROM information_schema.columns WHERE ...
COMMIT;
```

**FK Group A** (material lineage): all 6 columns in ONE transaction:
```sql
BEGIN;
  ALTER TABLE perseus.goo ALTER COLUMN uid TYPE citext;
  ALTER TABLE perseus.fatsmurf ALTER COLUMN uid TYPE citext;
  ALTER TABLE perseus.material_transition ALTER COLUMN material_id TYPE citext;
  ALTER TABLE perseus.material_transition ALTER COLUMN transition_id TYPE citext;
  ALTER TABLE perseus.transition_material ALTER COLUMN material_id TYPE citext;
  ALTER TABLE perseus.transition_material ALTER COLUMN transition_id TYPE citext;
COMMIT;
```

**Independent columns**: grouped by table, one transaction per table for efficiency.

- Post-ALTER verification per column: `information_schema.columns → udt_name = 'citext'`
- **Checkpoint**: manifest updated after each table completes
- Large tables: log estimated time before starting, show progress

**Failure modes addressed:**
- ALTER fails mid-transaction → automatic ROLLBACK (PostgreSQL transactional DDL)
- Lock timeout on large table → configurable `lock_timeout` setting
- Network interruption → resume skips already-converted tables (manifest has checksums)

### Phase 2b: ALTER Cache Tables (`02b-alter-cache-tables.py`)

**LAST tables to be converted in the entire process.** Direct ALTER (no TRUNCATE — sufficient downtime window).

For m_downstream (33.8M rows, 6.5GB), m_upstream (686M rows, 157GB), and m_upstream_dirty_leaves (0 rows):

```sql
-- m_upstream_dirty_leaves first (0 rows — instant)
ALTER TABLE perseus.m_upstream_dirty_leaves ALTER COLUMN material_uid TYPE citext;

-- m_downstream second (33.8M rows — estimated ~15-30 min)
ALTER TABLE perseus.m_downstream ALTER COLUMN start_point TYPE citext;
ALTER TABLE perseus.m_downstream ALTER COLUMN end_point TYPE citext;
ALTER TABLE perseus.m_downstream ALTER COLUMN path TYPE citext;

-- m_upstream LAST (686M rows — estimated hours, ACCESS EXCLUSIVE lock)
ALTER TABLE perseus.m_upstream ALTER COLUMN start_point TYPE citext;
ALTER TABLE perseus.m_upstream ALTER COLUMN end_point TYPE citext;
ALTER TABLE perseus.m_upstream ALTER COLUMN path TYPE citext;
```

**Runs AFTER Phase 2a** (all other tables must be CITEXT first).
Cache tables have NO FK constraints and NO dependent views — independent execution.

**Failure modes addressed:**
- Lock timeout on m_upstream → configurable `lock_timeout`; retry
- Disk space during table rewrite → Phase 0 checks ~1.5x table size available
- Network interruption → PostgreSQL auto-rollback; resume from manifest checkpoint

### Phase 3: Recreate Dependent Objects (`03-recreate-dependents.py`) — Bottom-Up

**Order**: Indexes → FK Constraints → Triggers → MV → Views (Wave 0 first)

```
Indexes:     All indexes on target columns (from saved DDL)
FK:          4 FK constraints (material lineage)
MV Wave 0:   translated (+ unique index + supporting indexes + triggers + grants)
             ** UPDATE translated.sql: change ::VARCHAR(50) to ::CITEXT on lines 100-102 **
Views Wave 1: upstream, downstream, material_transition_material
Views Wave 2: vw_lot, hermes_run, vw_lot_edge, vw_lot_path, vw_recipe_prep
Views Wave 3: vw_recipe_prep_part, vw_jeremy_runs, etc.
```

- Each CREATE logged with timestamp
- **Checkpoint**: manifest updated after each recreation
- Idempotent: uses `CREATE OR REPLACE VIEW` / `CREATE INDEX IF NOT EXISTS`

**Failure modes addressed:**
- View creation fails (syntax) → log error, continue with others, report at end
- MV refresh fails → retry once, then ABORT with guidance
- Index creation fails → log and continue (non-blocking)

### ~~Phase 4: Update Procedures~~ — DEFERRED (Future Worktree)

**NOT executed in this US7.** Procedures and functions that reference converted columns will be updated in a dedicated future User Story worktree.

**Deliverables for this US7 (documentation only):**
1. `docs/post-migration/CITEXT-PROCEDURES-UPDATE-GUIDE.md` — Detailed guide for the **human development team**: which procedures need updating, which parameters/variables, expected changes, and testing checklist.
2. `docs/post-migration/CITEXT-FUNCTIONS-UPDATE-GUIDE.md` — Same analysis for functions referencing converted columns.
3. `docs/post-migration/CITEXT-CLAUDE-AGENT-INSTRUCTIONS.md` — Instructions document for a **Claude agent** to use in a future worktree coding session to perform the actual procedure/function updates.

### Phase 4: Post-conversion Validation (`04-validate-conversion.py`)

1. **Column types**: All 172 columns → `udt_name = 'citext'`
2. **FK constraints**: All 4 FKs exist and valid (`pg_constraint`)
3. **Indexes**: All recreated indexes exist (`pg_indexes`)
4. **UNIQUE constraints**: Still enforced (test insert of case-variant)
5. **CHECK constraints**: Still enforced (test invalid value)
6. **Views**: All 22 views queryable (`SELECT 1 FROM {view} LIMIT 0`)
7. **MV populated**: `translated` has rows (`COUNT(*) > 0`)
8. **Case-insensitive behavior**: `WHERE goo.uid = 'ABC'` matches row with uid='abc'
9. **Lineage traversal**: Run sample upstream/downstream query, compare result count

### Phase 5: Report Generation (`05-generate-report.py`)

- Summary markdown: tables converted, columns changed, duration per phase
- Before/after comparison table
- Any warnings or manual action items
- Log archive location

---

## Script Architecture

```
scripts/post-migration/
  .env.example                           # DB connection config template
  requirements.txt                       # Python dependencies
  config/
    citext-conversion.yaml               # Target columns + FK groups
  00-preflight-check.py                  # Phase 0: connectivity, deps, duplicates
  01-drop-dependents.py                  # Phase 1: drop views, FKs, indexes
  02-alter-columns.py                    # Phase 2a: ALTER TYPE on regular tables
  02b-alter-cache-tables.py              # Phase 2b: Direct ALTER on cache tables (LAST)
  03-recreate-dependents.py              # Phase 3: recreate indexes, FKs, views
  04-validate-conversion.py              # Phase 4: comprehensive validation
  05-generate-report.py                  # Phase 5: summary report
  run-all.py                             # Orchestrator: phases 0-5 with resume
  rollback-citext.py                     # Full rollback from manifest
  lib/
    __init__.py
    db.py                                # psql connection via subprocess (reads .env)
    logger.py                            # Structured dual logging (console + file)
    manifest.py                          # JSON checkpoint manifest (resume + rollback)
    dependency.py                        # pg_catalog dependency graph builder
    sql_templates.py                     # SQL templates for DROP/CREATE/ALTER

tests/citext/                            # TDD tests (written BEFORE each script)
  __init__.py
  conftest.py                            # Shared fixtures (mock DB, temp manifest)
  test_lib_db.py
  test_lib_logger.py
  test_lib_manifest.py
  test_lib_dependency.py
  test_lib_sql_templates.py
  test_00_preflight_check.py
  test_01_drop_dependents.py
  test_02_alter_columns.py
  test_02b_alter_cache_tables.py
  test_03_recreate_dependents.py
  test_04_validate_conversion.py
  test_05_generate_report.py
  test_run_all.py
  test_rollback_citext.py
```

---

## Configuration

### .env.example
```env
# Database connection
PGHOST=localhost
PGPORT=5432
PGDATABASE=perseus_dev
PGUSER=perseus_admin
PGPASSWORD=
PGSCHEMA=perseus

# Execution settings
LOG_DIR=./logs
DRY_RUN=false
LOCK_TIMEOUT_MS=30000
STATEMENT_TIMEOUT_MS=0

# Resume support
MANIFEST_PATH=./manifest.json
```

### citext-conversion.yaml
```yaml
version: 1
schema: perseus
source_file: prompts/columns_citext_candidates.txt

fk_groups:
  - name: material_lineage
    description: "UID columns in FK relationships — MUST convert together"
    columns:
      - { table: goo, column: uid }
      - { table: fatsmurf, column: uid }
      - { table: material_transition, column: material_id }
      - { table: material_transition, column: transition_id }
      - { table: transition_material, column: material_id }
      - { table: transition_material, column: transition_id }

cache_tables:
  description: "LAST group — converted after ALL other tables. Direct ALTER (no truncate)."
  tables:
    - name: cache_downstream
      columns:
        - { table: m_downstream, column: start_point }
        - { table: m_downstream, column: end_point }
        - { table: m_downstream, column: path }
    - name: cache_upstream
      columns:
        - { table: m_upstream, column: start_point }
        - { table: m_upstream, column: end_point }
        - { table: m_upstream, column: path }
    - name: dirty_leaves
      columns:
        - { table: m_upstream_dirty_leaves, column: material_uid }

# All remaining columns from source_file are treated as independent
```

---

## Logging Strategy

**Dual output**: console (rich formatted) + log file

**Log file naming**: `{ordinal}-{step-name}-{YYYYMMDD-HHMMSS}.log`
Examples:
```
00-preflight-check-20260317-143022.log
01-drop-dependents-20260317-143155.log
02-alter-columns-20260317-143801.log
02b-alter-cache-tables-20260317-144500.log   # LAST phase for table conversion
03-recreate-dependents-20260317-150230.log
04-validate-conversion-20260317-151500.log
05-generate-report-20260317-152000.log
```

**Log content per operation**:
```
[2026-03-17 14:38:01.234] [INFO] Phase 2a: ALTER COLUMNS — Starting
[2026-03-17 14:38:01.235] [INFO] Table: perseus.goo (5,942,387 rows, 880 MB)
[2026-03-17 14:38:01.236] [SQL]  ALTER TABLE perseus.goo ALTER COLUMN uid TYPE citext;
[2026-03-17 14:38:15.891] [OK]   Column goo.uid converted in 14.655s
[2026-03-17 14:38:15.892] [SQL]  SELECT udt_name FROM information_schema.columns WHERE ...
[2026-03-17 14:38:15.920] [OK]   Verified: goo.uid → citext
[2026-03-17 14:38:15.921] [CHECKPOINT] Manifest updated: goo.uid COMPLETE
```

**On error**:
```
[2026-03-17 14:38:15.891] [ERROR] ALTER TABLE perseus.goo ALTER COLUMN uid TYPE citext;
[2026-03-17 14:38:15.892] [ERROR] SQLSTATE: 23505 — duplicate key violates unique constraint
[2026-03-17 14:38:15.893] [ERROR] DETAIL: Key (lower(uid))=('m12345') already exists
[2026-03-17 14:38:15.894] [ABORT] Phase 2a failed at goo.uid — run rollback-citext.py or fix and resume
```

---

## Resume / Checkpoint Mechanism

The `manifest.json` records the exact state after each operation:

```json
{
  "version": 1,
  "started_at": "2026-03-17T14:30:00Z",
  "last_updated": "2026-03-17T14:38:15Z",
  "current_phase": "02-alter-columns",
  "phases": {
    "00-preflight": { "status": "complete", "completed_at": "..." },
    "01-drop-dependents": {
      "status": "complete",
      "dropped": [
        { "type": "view", "name": "perseus.vw_recipe_prep_part", "ddl": "CREATE OR REPLACE VIEW ..." },
        { "type": "materialized_view", "name": "perseus.translated", "ddl": "..." }
      ]
    },
    "02-alter-columns": {
      "status": "in_progress",
      "completed": ["goo.uid", "goo.name", "goo.description"],
      "pending": ["goo.catalog_label", "fatsmurf.uid", "..."]
    }
  },
  "original_types": {
    "perseus.goo.uid": { "type": "character varying", "length": 50 },
    "perseus.goo.name": { "type": "character varying", "length": 250 }
  }
}
```

**Resume command**: `python run-all.py --resume`
- Reads manifest, skips completed phases/operations
- Validates current DB state matches manifest expectations
- Continues from last checkpoint

---

## Rollback Strategy

**Three levels**:

1. **Per-phase automatic**: Each phase runs in transactions where possible. Failed transaction = automatic PostgreSQL rollback.

2. **Manual resume + fix**: If Phase 2a fails on table X:
   - Manifest shows exactly which tables completed and which failed
   - Fix the issue (e.g., remove duplicate), then `python run-all.py --resume`

3. **Full rollback**: `python rollback-citext.py`
   - Reads manifest → reverses ALL completed operations
   - Drops recreated views/indexes/FKs
   - ALTER columns back to original VARCHAR(N) types (lengths stored in manifest)
   - Recreates original views/indexes/FKs from saved DDL
   - Refreshes materialized view

---

## Operator Execution Manual

A separate document `docs/post-migration/OPERATOR-MANUAL.md` will contain:

### Pre-requisites (Operator Workstation)
1. **Python 3.10+** with pip
2. **psql** (PostgreSQL client) — must be in PATH
3. **Network access** to PostgreSQL instance (port 5432 or configured)
4. **Database credentials** with ALTER, DROP, CREATE privileges on target schema
5. **Dependencies**: `pip install -r scripts/post-migration/requirements.txt`
   - `python-dotenv` (env file loading)
   - `pyyaml` (config parsing)
   - `rich` (console output formatting)

### Pre-execution Checklist
- [ ] Copy `.env.example` to `.env` and fill in credentials
- [ ] Verify connectivity: `python 00-preflight-check.py --test-connection`
- [ ] Run pre-flight: `python 00-preflight-check.py` — review report
- [ ] Confirm maintenance window (estimated: 2-4h for full conversion)
- [ ] Notify users of planned downtime
- [ ] Take database backup: `pg_dump -Fc perseus_dev > backup_pre_citext.dump`

### Execution
```bash
# Full run (all phases sequentially):
python run-all.py

# Or phase-by-phase (for manual control):
python 00-preflight-check.py
python 01-drop-dependents.py
python 02-alter-columns.py
python 02b-alter-cache-tables.py
python 03-recreate-dependents.py
python 04-validate-conversion.py
python 05-generate-report.py

# Resume after interruption:
python run-all.py --resume

# Dry run (no changes, only shows SQL):
python run-all.py --dry-run

# Rollback everything:
python rollback-citext.py
```

### Post-execution Checklist
- [ ] Review validation report (`05-validate-conversion` output)
- [ ] Review generated report (`06-generate-report` output)
- [ ] Verify application connectivity
- [ ] Run application smoke tests
- [ ] Notify users that maintenance is complete

---

## Edge Cases & Failure Scenarios

| # | Scenario | Detection | Mitigation |
|---|----------|-----------|------------|
| 1 | Case-variant duplicates on UNIQUE columns (e.g., 'ABC' and 'abc' in goo.uid) | Phase 0 duplicate check | ABORT — operator must resolve duplicates before conversion |
| 2 | FK type mismatch (parent CITEXT, child VARCHAR) | Phase 0 dependency graph | FK group forces parent+child conversion in same transaction |
| 3 | `translated` MV has `::VARCHAR(50)` casts (lines 100-102) | Known — hardcoded in Phase 3 | Update to `::CITEXT` before recreation |
| 4 | Procedures/functions with VARCHAR params mismatched after conversion | **DEFERRED** — documented in CITEXT-PROCEDURES-UPDATE-GUIDE.md + CITEXT-FUNCTIONS-UPDATE-GUIDE.md | Future worktree will update signatures |
| 5 | Network interruption mid-ALTER on large table | PostgreSQL auto-rollback | Resume from manifest checkpoint |
| 6 | Disk space exhaustion during table rewrite | Phase 0 space check | WARN if <2x table size available |
| 7 | Lock timeout on large table (concurrent access) | `lock_timeout` setting in .env | Configurable timeout; retry with higher value |
| 8 | FDW tables (hermes.run) can't be converted | Phase 0 excludes FDW tables | Skip — remote server controls types |
| 9 | Cache table ALTER takes hours (m_upstream 686M rows) | Expected behavior | Direct ALTER with progress logging; schedule in maintenance window |
| 10 | Scraper table (179K rows, 80GB — LOBs) | Phase 0 size check | Warn operator; may need extended window |
| 11 | `m_upstream_dirty_leaves` references material UIDs | Included in cache group | Converted with cache tables |
| 12 | CHECK constraints on submission_entry | Phase 0 analysis | Compatible — text comparison semantics unchanged |
| 13 | DEFAULT gen_random_uuid() on container.scope_id | Phase 0 analysis | Compatible — UUID returns TEXT, auto-casts to CITEXT |
| 14 | `upstream`/`downstream` path concatenation | Phase 0 analysis | `||` operator works identically with CITEXT |
| 15 | Views with CAST expressions to VARCHAR | Phase 3 flags | Update CASTs to CITEXT where applicable |

---

## Documentation Deliverables (docs/post-migration/)

| Document | Content |
|----------|---------|
| `citext-dependency-analysis.md` | Full dependency graph, FK chains, mermaid ER/dependency diagrams |
| `citext-deployment-workflow.md` | Phase flowchart (mermaid), step descriptions, rollback points |
| `citext-table-grouping.md` | Tables by volume (<500K vs >=500K), estimated ALTER times |
| `OPERATOR-MANUAL.md` | Pre-requisites, setup, execution steps, troubleshooting |
| `CITEXT-PROCEDURES-UPDATE-GUIDE.md` | For human dev team: which procedures need VARCHAR→CITEXT updates, parameters/variables list, testing checklist |
| `CITEXT-FUNCTIONS-UPDATE-GUIDE.md` | For human dev team: which functions reference converted columns, required changes |
| `CITEXT-CLAUDE-AGENT-INSTRUCTIONS.md` | For Claude agent in future worktree: context, scope, step-by-step instructions to update procedures/functions |

---

## TDD Methodology

**MANDATORY**: Every script is developed using Test-Driven Development. The workflow for each script is:

1. **Write tests FIRST** in `tests/citext/test_{script_name}.py`
2. **Run tests** — they must fail (RED phase)
3. **Implement the script** in `scripts/post-migration/`
4. **Run tests again** — they must pass (GREEN phase)
5. **Refactor** if needed, ensuring tests still pass
6. **Only then** proceed to the next script

**Test directory structure:**
```
tests/
  citext/
    __init__.py
    conftest.py                          # Shared fixtures (mock DB, temp manifest, etc.)
    test_lib_db.py                       # Tests for lib/db.py
    test_lib_logger.py                   # Tests for lib/logger.py
    test_lib_manifest.py                 # Tests for lib/manifest.py
    test_lib_dependency.py               # Tests for lib/dependency.py
    test_lib_sql_templates.py            # Tests for lib/sql_templates.py
    test_00_preflight_check.py           # Tests for 00-preflight-check.py
    test_01_drop_dependents.py           # Tests for 01-drop-dependents.py
    test_02_alter_columns.py             # Tests for 02-alter-columns.py
    test_02b_alter_cache_tables.py       # Tests for 02b-alter-cache-tables.py
    test_03_recreate_dependents.py       # Tests for 03-recreate-dependents.py
    test_04_validate_conversion.py       # Tests for 04-validate-conversion.py
    test_05_generate_report.py           # Tests for 05-generate-report.py
    test_run_all.py                      # Tests for run-all.py orchestrator
    test_rollback_citext.py              # Tests for rollback-citext.py
```

**Test runner**: `pytest tests/citext/ -v`

**Test categories:**
- **Unit tests**: Mock DB calls, test logic in isolation (config parsing, manifest operations, SQL generation, dependency graph building)
- **Integration tests** (optional, requires DB): Test actual psql execution against a test schema

---

## Task Breakdown

Each script task includes its TDD cycle: write test → fail → implement → pass → next.

| # | Task | Deliverable | Depends On | Gate |
|---|------|-------------|------------|------|
| T1 | Create `docs/post-migration/citext-dependency-analysis.md` with mermaid diagrams | Doc | - | - |
| T2 | Create `docs/post-migration/citext-deployment-workflow.md` with flowchart | Doc | - | - |
| T3 | Create `docs/post-migration/citext-table-grouping.md` with volume analysis | Doc | - | - |
| T4a | Create `tests/citext/conftest.py` + shared fixtures | Test | - | - |
| T4b | **TDD**: `tests/citext/test_lib_*.py` → then implement `lib/` (db, logger, manifest, dependency, sql_templates) | Code+Test | T4a | All lib tests GREEN |
| T5 | Create `scripts/post-migration/.env.example` + `config/citext-conversion.yaml` | Config | - | - |
| T6 | **TDD**: `tests/citext/test_00_preflight_check.py` → then implement `00-preflight-check.py` | Code+Test | T4b | Tests GREEN |
| T7 | **TDD**: `tests/citext/test_01_drop_dependents.py` → then implement `01-drop-dependents.py` | Code+Test | T6 GREEN | Tests GREEN |
| T8 | **TDD**: `tests/citext/test_02_alter_columns.py` → then implement `02-alter-columns.py` | Code+Test | T7 GREEN | Tests GREEN |
| T9 | **TDD**: `tests/citext/test_02b_alter_cache_tables.py` → then implement `02b-alter-cache-tables.py` | Code+Test | T8 GREEN | Tests GREEN |
| T10 | **TDD**: `tests/citext/test_03_recreate_dependents.py` → then implement `03-recreate-dependents.py` | Code+Test | T7 GREEN | Tests GREEN |
| T11 | **TDD**: `tests/citext/test_04_validate_conversion.py` → then implement `04-validate-conversion.py` | Code+Test | T10 GREEN | Tests GREEN |
| T12 | **TDD**: `tests/citext/test_05_generate_report.py` → then implement `05-generate-report.py` | Code+Test | T11 GREEN | Tests GREEN |
| T13 | **TDD**: `tests/citext/test_run_all.py` → then implement `run-all.py` (--resume, --dry-run) | Code+Test | T6-T12 GREEN | Tests GREEN |
| T14 | **TDD**: `tests/citext/test_rollback_citext.py` → then implement `rollback-citext.py` | Code+Test | T4b GREEN | Tests GREEN |
| T15 | Create `docs/post-migration/OPERATOR-MANUAL.md` | Doc | T13 | - |
| T16 | Create `docs/post-migration/CITEXT-PROCEDURES-UPDATE-GUIDE.md` — detailed guide for human dev team (procedures) | Doc | T6 | - |
| T17 | Create `docs/post-migration/CITEXT-FUNCTIONS-UPDATE-GUIDE.md` — detailed guide for human dev team (functions) | Doc | T6 | - |
| T18 | Create `docs/post-migration/CITEXT-CLAUDE-AGENT-INSTRUCTIONS.md` — instructions for Claude agent in future worktree | Doc | T16, T17 | - |
| T19 | Save plan copy to `docs/plans/` | Doc | - | - |

---

## Verification Plan

1. `python 00-preflight-check.py --test-connection` — connectivity OK
2. `python run-all.py --dry-run` — all phases produce correct SQL without executing
3. Test on single small table: modify YAML to include only `color.name` (108 rows), run full pipeline
4. Verify rollback: `python rollback-citext.py`, confirm `color.name` is back to VARCHAR
5. Run full conversion with all 172 columns
6. `python 04-validate-conversion.py` — all 172 columns confirmed CITEXT
7. Test application queries against converted database

---

## Critical Files to Reference

| File | Purpose |
|------|---------|
| `prompts/columns_citext_candidates.txt` | Source list of 172 columns to convert |
| `source/building/pgsql/refactored/17.create-constraint/02-foreign-key-constraints.sql` | FK DDL (lines 964-996 for VARCHAR FKs) |
| `source/building/pgsql/refactored/15.create-view/translated.sql` | MV with `::VARCHAR(50)` casts (lines 100-102) |
| `source/building/pgsql/refactored/15.create-view/*.sql` | All 22 view definitions |
| `source/building/pgsql/refactored/16.create-index/*.sql` | Index definitions on target columns |
| `source/building/pgsql/refactored/20.create-procedure/*.sql` | 15 procedures to update |
| `docs/data-assessments/all_perseus_rowcount_table_size.csv` | Table volume data |
| `docs/code-analysis/dependency/fk-relationship-matrix.md` | FK relationship reference |
| `scripts/deployment/deploy-batch.sh` | Pattern: error handling, logging, env vars |
| `scripts/automation/analyze-object.py` | Pattern: Python CLI structure (argparse, Path, rich) |
