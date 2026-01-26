# Perseus Data Migration Scripts - DEV Environment

**Purpose:** Extract 15% sample data from SQL Server and load into PostgreSQL DEV environment with full referential integrity.

**Status:** Complete and ready for execution

---

## 📋 Overview

This directory contains a **6-phase data migration workflow** designed to:

1. **Extract** 15% sample from SQL Server (769 database objects → ~95 tables)
2. **Maintain referential integrity** via cascading FK-aware sampling
3. **Load** data into PostgreSQL in dependency order (5 tiers)
4. **Validate** referential integrity, row counts, and data checksums

**Critical Success Factors:**
- ✅ Zero orphaned FK relationships
- ✅ 15% ±2% variance acceptable (13-17%)
- ✅ P0 critical tables validated: `goo`, `fatsmurf`, `material_transition`, `transition_material`
- ✅ UID-based FKs handled correctly (not integer PK/FK)

---

## 🗂️ Files in This Directory

### Extraction Scripts (SQL Server)

| File | Purpose | Tables | Dependencies |
|------|---------|--------|--------------|
| `extract-tier0.sql` | Extract 15% random sample from base tables | 32 | None (random 15%) |
| `extract-tier1.sql` | Extract 15% with FK filtering | 10 | Tier 0 temp tables |
| `extract-tier2.sql` | Extract 15% with FK filtering | 11 | Tier 0-1 temp tables |
| `extract-tier3.sql` | Extract P0 critical + 12 other tables | 12 | Tier 0-2 temp tables |
| `extract-tier4.sql` | Extract P0 lineage + 11 other tables | 11 | Tier 0-3 temp tables |

**Total:** 76 tables extracted with cascading FK-aware sampling

### Loading Scripts (PostgreSQL)

| File | Purpose | Usage |
|------|---------|-------|
| `load-data.sh` | Orchestrate CSV loading in dependency order | `./load-data.sh` |

### Validation Scripts (PostgreSQL)

| File | Purpose | Usage |
|------|---------|-------|
| `validate-referential-integrity.sql` | Check all 121 FK constraints | `psql -f validate-referential-integrity.sql` |
| `validate-row-counts.sql` | Verify 15% sampling rate | `psql -f validate-row-counts.sql` |
| `validate-checksums.sql` | Sample-based data integrity | `psql -f validate-checksums.sql` |

---

## 🚀 Quick Start

### Prerequisites

1. **SQL Server Access** (source database)
   - Connection to `perseus` database
   - Read permissions on all tables
   - SQL Server Management Studio (SSMS) or `sqlcmd`

2. **PostgreSQL DEV Environment** (target database)
   - Container: `perseus-postgres-dev` running
   - Schema: `perseus` with all tables/indexes/constraints deployed
   - User: `perseus_admin` with write permissions

3. **CSV Export Directory**
   - Default: `/tmp/perseus-data-export`
   - Or set: `export DATA_DIR=/path/to/export`

### Execution Steps

#### Phase 1: Extract Data from SQL Server

```bash
# Connect to SQL Server
sqlcmd -S <server> -d perseus -U <user> -P <password>

# Execute extraction scripts IN ORDER
:r extract-tier0.sql
GO
:r extract-tier1.sql
GO
:r extract-tier2.sql
GO
:r extract-tier3.sql
GO
:r extract-tier4.sql
GO
```

**Output:** 76 temp tables (`#temp_*`) with 15% sample data

#### Phase 2: Export Temp Tables to CSV

**Option A: Using BCP (Command Line)**

```bash
# Export all temp tables to CSV
for table in $(sqlcmd -S <server> -d tempdb -Q "SELECT name FROM tempdb.sys.tables WHERE name LIKE '#temp_%'" -h-1 -W)
do
  bcp "SELECT * FROM tempdb..${table}" queryout "${DATA_DIR}/${table#temp_}.csv" \
    -c -t"," -r"\n" -S <server> -U <user> -P <password>
done
```

**Option B: Using SSMS (GUI)**

1. Right-click `tempdb` database → **Tasks** → **Export Data**
2. Select **Flat File Destination**
3. Choose all `#temp_*` tables
4. Export to `/tmp/perseus-data-export/`
5. Format: CSV with headers

#### Phase 3: Load Data into PostgreSQL

```bash
# Ensure database container is running
docker ps | grep perseus-postgres-dev

# Set data directory (if not default)
export DATA_DIR=/tmp/perseus-data-export

# Load all data in dependency order
cd scripts/data-migration
./load-data.sh
```

**Options:**
```bash
# Load specific tier only
./load-data.sh --tier 0
./load-data.sh --tier 3

# Validation mode (skip loading)
./load-data.sh --validate-only
```

**Output:**
- Log file: `scripts/data-migration/load-data.log`
- Expected duration: 5-10 minutes
- Expected rows: ~TBD (depends on SQL Server source counts)

#### Phase 4: Validate Data Integrity

```bash
# 1. Referential Integrity (CRITICAL)
psql -U perseus_admin -d perseus_dev -f validate-referential-integrity.sql

# Expected: All FK constraints pass (0 orphaned rows)

# 2. Row Counts
psql -U perseus_admin -d perseus_dev -f validate-row-counts.sql

# Expected: 15% ±2% for all tables

# 3. Checksums (Sample-Based)
psql -U perseus_admin -d perseus_dev -f validate-checksums.sql

# Expected: Aggregate checksums match SQL Server (manual comparison)
```

---

## 🔍 Technical Details

### Sampling Strategy: Cascading FK-Aware

**Problem:** Random 15% sampling breaks FK relationships (orphaned rows).

**Solution:** Cascading FK-aware sampling across tiers:

```sql
-- TIER 0: Random 15% (no FK dependencies)
SELECT TOP 15 PERCENT * FROM dbo.goo_type ORDER BY NEWID();

-- TIER 1+: 15% of rows WITH valid FK values
WITH valid_goo_types AS (
    SELECT goo_type_id FROM #temp_goo_type
)
SELECT TOP 15 PERCENT *
FROM dbo.goo
WHERE goo_type_id IN (SELECT goo_type_id FROM valid_goo_types)
ORDER BY NEWID();
```

**Result:** Zero orphaned FK relationships, ~15% data across all tiers.

### UID-Based Foreign Keys (CRITICAL)

**Tables:** `material_transition`, `transition_material`

**Challenge:** These tables use VARCHAR `uid` columns (not integer `id`) for FK references.

**Solution:**
1. Created UNIQUE indexes on `goo.uid` and `fatsmurf.uid`
2. Modified extraction scripts to filter by `uid` values:

```sql
-- Tier 4 extraction (UID-based FK filtering)
WITH valid_goo_uids AS (
    SELECT uid FROM #temp_goo WHERE uid IS NOT NULL
),
valid_fatsmurf_uids AS (
    SELECT uid FROM #temp_fatsmurf WHERE uid IS NOT NULL
)
SELECT TOP 15 PERCENT mt.*
INTO #temp_material_transition
FROM dbo.material_transition mt
WHERE mt.material_id IN (SELECT uid FROM valid_goo_uids)
  AND mt.transition_id IN (SELECT uid FROM valid_fatsmurf_uids)
ORDER BY NEWID();
```

**Validation:** Check `validate-referential-integrity.sql` for UID-based FK checks.

### Dependency Tiers

| Tier | Description | Tables | Example Tables |
|------|-------------|--------|----------------|
| 0 | Base tables (no FK dependencies) | 32 | `goo_type`, `unit`, `manufacturer`, `container` |
| 1 | Depend only on Tier 0 | 10 | `property`, `perseus_user`, `workflow` |
| 2 | Depend on Tier 0-1 | 11 | `recipe`, `smurf_group`, `workflow_step` |
| 3 | Depend on Tier 0-2 (P0 CRITICAL) | 12 | `goo`, `fatsmurf`, `goo_attachment` |
| 4 | Depend on Tier 0-3 (P0 LINEAGE) | 11 | `material_transition`, `transition_material` |

### Load Order in `load-data.sh`

```bash
# Tier 0: Base tables
TIER0_TABLES=(
    "Permissions" "unit" "goo_type" "manufacturer" "container" ...
)

# Tier 1: Single-level FK dependencies
TIER1_TABLES=(
    "property" "perseus_user" "workflow" ...
)

# ... Tier 2, 3, 4

# Load in order
load_tier 0 "${TIER0_TABLES[@]}"
load_tier 1 "${TIER1_TABLES[@]}"
load_tier 2 "${TIER2_TABLES[@]}"
load_tier 3 "${TIER3_TABLES[@]}"
load_tier 4 "${TIER4_TABLES[@]}"
```

---

## ✅ Validation Criteria

### 1. Referential Integrity (PASS/FAIL)

- **Status:** `✓ PASS` if 0 orphaned FK rows
- **Script:** `validate-referential-integrity.sql`
- **Critical Checks:**
  - All 121 FK constraints
  - UID-based FKs: `material_transition`, `transition_material`

### 2. Row Count Variance (±2% acceptable)

- **Target:** 15% ±2% (13-17% acceptable)
- **Script:** `validate-row-counts.sql`
- **Status:**
  - `✓ PASS`: 13-17%
  - `⚠ WARNING`: 10-13% or 17-20%
  - `✗ FAIL`: <10% or >20%

### 3. Data Integrity Checksums (Manual Comparison)

- **Method:** MD5 checksums of 100-row samples
- **Script:** `validate-checksums.sql`
- **Tables:** 9 critical tables (P0 + key dependencies)
- **Validation:** Run equivalent queries on SQL Server, compare `aggregate_checksum`

---

## 🐛 Troubleshooting

### Issue 1: Orphaned FK Rows

**Symptom:** `validate-referential-integrity.sql` reports failures

**Causes:**
- FK filter logic incorrect in extraction scripts
- Temp table missing rows (extraction interrupted)

**Fix:**
1. Re-run extraction scripts from Tier 0
2. Verify temp table row counts: `SELECT COUNT(*) FROM #temp_<table>`
3. Check FK filter logic: `WHERE fk_column IN (SELECT id FROM #temp_parent)`

### Issue 2: Row Count Variance >2%

**Symptom:** Actual percentage is 10% or 20% (not 15%)

**Causes:**
- FK filtering reduces available rows (sparse FK distribution)
- Random sampling variance (acceptable for small tables)

**Fix:**
- **Acceptable:** Variance <5% for tables with >1000 rows
- **Investigate:** Variance >5% or tables with <100 rows
- **Solution:** Adjust `TOP 15 PERCENT` to `TOP 20 PERCENT` for affected tiers

### Issue 3: Checksum Mismatches

**Symptom:** PostgreSQL checksum ≠ SQL Server checksum

**Causes:**
- Data type conversion issues (timestamps, booleans)
- NULL handling differences (`ISNULL` vs `COALESCE`)
- String trimming (CHAR vs VARCHAR)

**Fix:**
1. Check timestamp precision (SQL Server: 3.33ms, PostgreSQL: 1μs)
2. Verify boolean conversions (bit 0/1 vs boolean true/false)
3. Review NULL handling in checksum queries
4. **Acceptable:** Timestamp differences <4ms

### Issue 4: Load Script Failures

**Symptom:** `load-data.sh` fails mid-tier

**Causes:**
- CSV file missing or corrupted
- Database container not running
- Permissions issue

**Fix:**
```bash
# Check container status
docker ps | grep perseus-postgres-dev

# Verify CSV files exist
ls -lh $DATA_DIR/*.csv

# Check database connection
psql -U perseus_admin -d perseus_dev -c "SELECT 1;"

# Re-run specific tier
./load-data.sh --tier 3
```

---

## 📊 Expected Metrics (DEV Environment)

| Metric | Expected Value | Source |
|--------|----------------|--------|
| **Tables Loaded** | 76-93 | Depends on CSV availability |
| **Total Rows** | ~TBD | 15% of SQL Server source |
| **FK Constraints** | 121 | All should pass validation |
| **Orphaned Rows** | 0 | Referential integrity requirement |
| **Load Duration** | 5-10 minutes | Docker container performance |
| **Validation Duration** | 2-3 minutes | All 3 validation scripts |

**P0 Critical Tables (Row Count Examples):**

| Table | Est. Source Rows | Est. DEV Rows (15%) | Priority |
|-------|------------------|---------------------|----------|
| `goo` | ~500,000 | ~75,000 | P0 |
| `fatsmurf` | ~200,000 | ~30,000 | P0 |
| `material_transition` | ~1,000,000 | ~150,000 | P0 |
| `transition_material` | ~1,000,000 | ~150,000 | P0 |
| `goo_type` | ~500 | ~75 | P1 |
| `perseus_user` | ~200 | ~30 | P1 |

**Note:** Replace estimates with actual SQL Server counts from `PerseusTableAndRowCounts` table.

---

## 📝 Success Checklist

Before marking data migration as complete:

- [ ] **Phase 1:** All 5 extraction scripts executed successfully
- [ ] **Phase 2:** All 76 CSV files exported to `$DATA_DIR`
- [ ] **Phase 3:** `load-data.sh` completed with 0 errors
- [ ] **Phase 4a:** `validate-referential-integrity.sql` - ALL PASS (0 failures)
- [ ] **Phase 4b:** `validate-row-counts.sql` - 15% ±2% variance
- [ ] **Phase 4c:** `validate-checksums.sql` - Manual comparison with SQL Server
- [ ] **P0 Critical:** `goo`, `fatsmurf`, `material_transition`, `transition_material` validated
- [ ] **Documentation:** Results logged in `tracking/activity-log-2026-01.md`
- [ ] **Stakeholder:** DBA approval for DEV data quality

---

## 🔗 Related Documentation

- **Project Overview:** `docs/PROJECT-SPECIFICATION.md`
- **User Story 3:** `specs/001-tsql-to-pgsql/tasks.md` (T126-T131)
- **Table Structures:** `docs/code-analysis/table-dependency-graph.md`
- **FK Constraint Fixes:** `docs/FK-CONSTRAINT-FIXES.md`
- **DEV Deployment:** `docs/DEV-DEPLOYMENT-COMPLETE.md`
- **Data Migration Plan:** `docs/DATA-MIGRATION-PLAN-DEV.md`

---

## 📞 Support

**Issues?** Contact:
- **DBA:** Pierre Ribeiro (Senior DBA/DBRE)
- **Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
- **Tracker:** `tracking/progress-tracker.md`

**Last Updated:** 2026-01-26 | **Version:** 1.0
