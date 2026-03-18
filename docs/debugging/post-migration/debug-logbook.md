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

## Cleanup

- Deleted `scripts/post-migration/manifest.json` for clean re-run after fixes.
