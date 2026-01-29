# Data Migration Plan - DEV Environment (15% Sample)

**Date**: 2026-01-26
**Target**: perseus_dev database
**Strategy**: 15% row sampling with referential integrity preservation
**Source**: SQL Server Production (Perseus database)

---

## Executive Summary

**Objective**: Load representative sample data (15% of production) into DEV database for testing and validation purposes.

**Key Requirements**:
1. ✅ Maintain referential integrity (all FK relationships valid)
2. ✅ Load data in dependency order (parent tables before child tables)
3. ✅ Extract exactly 15% of rows from each table
4. ✅ Validate 100% data integrity after load
5. ✅ Preserve CASCADE DELETE chains

**Estimated Time**: 2-4 hours (depends on SQL Server network latency)

---

## Migration Strategy

### Phase 1: Dependency-Ordered Extraction (Tier-by-Tier)

**Key Principle**: Extract parent tables FIRST, then child tables using FK relationships to filter.

#### Tier 0 Tables (No FK Dependencies) - Extract 15% Randomly
```sql
-- Example: manufacturer table
SELECT TOP 15 PERCENT *
FROM perseus.dbo.manufacturer
ORDER BY NEWID();  -- Random sampling
```

**Tables**: manufacturer, color, display_type, unit, goo_type, etc. (38 tables)

#### Tier 1+ Tables (With FK Dependencies) - Extract 15% WITH FK Filtering
```sql
-- Example: goo table (depends on goo_type)
WITH sampled_goo_types AS (
    SELECT goo_type_id
    FROM #temp_goo_type  -- Already extracted Tier 0 data
)
SELECT TOP 15 PERCENT g.*
FROM perseus.dbo.goo g
WHERE g.goo_type_id IN (SELECT goo_type_id FROM sampled_goo_types)
ORDER BY NEWID();
```

**Critical**: Child table extraction MUST filter by parent PKs already extracted.

---

## Detailed Execution Plan

### T126: Extract Production Data from SQL Server (Tier-by-Tier)

#### Step 1: Create Extraction Script Template
**File**: `scripts/data-migration/extract-tier-data.sql`

```sql
-- ============================================================================
-- SQL Server Data Extraction Script (15% Sampling)
-- Tier: {TIER_NUMBER}
-- Tables: {TABLE_LIST}
-- ============================================================================

-- Set extraction parameters
DECLARE @sample_pct INT = 15;

-- Extract Tier 0 table: manufacturer
SELECT TOP (@sample_pct) PERCENT *
INTO #temp_manufacturer
FROM perseus.dbo.manufacturer
ORDER BY NEWID();

-- Export to CSV
bcp "SELECT * FROM #temp_manufacturer" queryout
  "/tmp/manufacturer.csv"
  -c -t"," -r"\n"
  -S {SQL_SERVER} -U {USER} -P {PASSWORD};

-- Extract Tier 1 table: goo (depends on goo_type from Tier 0)
WITH sampled_parents AS (
    SELECT goo_type_id FROM #temp_goo_type
)
SELECT TOP (@sample_pct) PERCENT g.*
INTO #temp_goo
FROM perseus.dbo.goo g
WHERE g.goo_type_id IN (SELECT goo_type_id FROM sampled_parents)
ORDER BY NEWID();

-- Export to CSV
bcp "SELECT * FROM #temp_goo" queryout
  "/tmp/goo.csv"
  -c -t"," -r"\n"
  -S {SQL_SERVER} -U {USER} -P {PASSWORD};
```

#### Step 2: Execute Extraction in Dependency Order
**Order**: Follow `docs/code-analysis/table-creation-order.md`

**Tier 0** (38 tables) → **Tier 1** (10 tables) → **Tier 2** (19 tables) → **Tier 3** (15 tables) → **Tier 4** (11 tables)

**Output**: 93 CSV files in `/tmp/perseus-data-export/`

---

### T127: Create Data Migration Scripts

#### Script 1: `scripts/data-migration/load-data.sh`
**Purpose**: Orchestrate data loading in dependency order

```bash
#!/bin/bash
set -euo pipefail

# Configuration
DB_CONTAINER="perseus-postgres-dev"
DB_NAME="perseus_dev"
DB_USER="perseus_admin"
DATA_DIR="/tmp/perseus-data-export"

echo "Starting data migration (15% sample)..."

# Tier 0: Load base tables (no dependencies)
for table in manufacturer color display_type unit goo_type; do
    echo "Loading $table..."
    docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
      "COPY perseus.$table FROM STDIN WITH CSV HEADER;" < "$DATA_DIR/$table.csv"
done

# Tier 1: Load tables with Tier 0 dependencies
for table in container property workflow perseus_user; do
    echo "Loading $table..."
    docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
      "COPY perseus.$table FROM STDIN WITH CSV HEADER;" < "$DATA_DIR/$table.csv"
done

# Continue for Tiers 2-4...

echo "Data migration complete!"
```

#### Script 2: `scripts/data-migration/validate-referential-integrity.sql`
**Purpose**: Validate all FK relationships after load

```sql
-- ============================================================================
-- Referential Integrity Validation Script
-- Purpose: Verify all FK relationships are valid after data load
-- ============================================================================

DO $$
DECLARE
    fk_violation_count INT := 0;
    rec RECORD;
BEGIN
    -- Check all FK constraints
    FOR rec IN
        SELECT
            conname AS constraint_name,
            conrelid::regclass AS child_table,
            confrelid::regclass AS parent_table,
            a.attname AS child_column,
            af.attname AS parent_column
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
        JOIN pg_attribute af ON af.attrelid = c.confrelid AND af.attnum = ANY(c.confkey)
        WHERE c.contype = 'f'
          AND connamespace = 'perseus'::regnamespace
    LOOP
        -- Check for orphaned rows
        EXECUTE format(
            'SELECT COUNT(*) FROM %s child
             WHERE child.%I NOT IN (SELECT %I FROM %s)',
            rec.child_table, rec.child_column, rec.parent_column, rec.parent_table
        ) INTO fk_violation_count;

        IF fk_violation_count > 0 THEN
            RAISE WARNING 'FK Violation: % - % orphaned rows in %.%',
                rec.constraint_name, fk_violation_count,
                rec.child_table, rec.child_column;
        END IF;
    END LOOP;

    RAISE NOTICE 'Referential integrity check complete.';
END $$;
```

---

### T128: Load Data in Dependency Order

**Execution Strategy**:
1. Disable FK constraints temporarily: `SET session_replication_role = 'replica';`
2. Load all data in dependency order
3. Re-enable FK constraints: `SET session_replication_role = 'origin';`
4. Validate all constraints

**Alternative Strategy** (Safer):
1. Keep FK constraints enabled
2. Load data strictly in dependency order
3. Any FK violation will fail immediately (easier debugging)

**Recommendation**: Use Alternative Strategy for DEV (safer, easier to debug)

---

### T129: Row Count Validation

#### Script: `scripts/data-migration/validate-row-counts.sql`

```sql
-- ============================================================================
-- Row Count Validation
-- Purpose: Compare row counts between source and target
-- ============================================================================

CREATE TEMP TABLE row_count_comparison (
    table_name VARCHAR(100),
    source_rows INTEGER,
    target_rows INTEGER,
    expected_pct NUMERIC(5,2),
    actual_pct NUMERIC(5,2),
    status VARCHAR(20)
);

-- Insert expected counts (from SQL Server extraction log)
INSERT INTO row_count_comparison (table_name, source_rows, expected_pct)
VALUES
    ('manufacturer', 150, 15.0),  -- Example: 1000 rows * 15% = 150
    ('goo', 15000, 15.0),          -- Example: 100000 rows * 15% = 15000
    -- ... all tables ...
;

-- Get actual counts from PostgreSQL
UPDATE row_count_comparison
SET target_rows = (
    SELECT COUNT(*)
    FROM perseus.manufacturer
)
WHERE table_name = 'manufacturer';

-- Calculate actual percentage
UPDATE row_count_comparison
SET actual_pct = (target_rows::NUMERIC / NULLIF(source_rows, 0)) * 100,
    status = CASE
        WHEN target_rows = source_rows THEN 'MATCH'
        WHEN ABS(target_rows - source_rows) < 10 THEN 'CLOSE'
        ELSE 'MISMATCH'
    END;

-- Report
SELECT
    table_name,
    source_rows,
    target_rows,
    expected_pct,
    actual_pct,
    status
FROM row_count_comparison
ORDER BY status DESC, table_name;
```

---

### T130: Checksum Validation (Sample-Based)

**Strategy**: Validate data integrity on a sample of rows (not full 15%, too expensive)

#### Script: `scripts/data-migration/validate-checksums.sql`

```sql
-- ============================================================================
-- Checksum Validation (Sample-Based)
-- Purpose: Validate data integrity for critical tables
-- ============================================================================

-- Example: Validate goo table (sample 100 rows)
WITH source_checksums AS (
    -- This would come from SQL Server pre-extracted checksums
    SELECT goo_id, checksum_value FROM temp_source_checksums
),
target_checksums AS (
    SELECT
        goo_id,
        MD5(ROW(goo_id, name, description, goo_type_id, created_on)::TEXT) AS checksum_value
    FROM perseus.goo
    WHERE goo_id IN (SELECT goo_id FROM source_checksums)
)
SELECT
    s.goo_id,
    s.checksum_value AS source_checksum,
    t.checksum_value AS target_checksum,
    CASE WHEN s.checksum_value = t.checksum_value THEN 'MATCH' ELSE 'MISMATCH' END AS status
FROM source_checksums s
LEFT JOIN target_checksums t ON s.goo_id = t.goo_id
WHERE s.checksum_value != t.checksum_value OR t.checksum_value IS NULL;
```

**Critical Tables for Checksum Validation**:
- goo (core material data)
- material_transition (lineage edges)
- transition_material (lineage edges)
- fatsmurf (experiments)

---

### T131: Verify Zero Data Loss

**Validation Checklist**:

```sql
-- 1. Row counts within expected range (15% ± 1%)
SELECT COUNT(*) FROM perseus.goo;  -- Should be ~15% of source

-- 2. No NULL PKs
SELECT COUNT(*) FROM perseus.goo WHERE goo_id IS NULL;  -- Should be 0

-- 3. No orphaned FKs
-- (Use validate-referential-integrity.sql from T127)

-- 4. No duplicate PKs
SELECT goo_id, COUNT(*)
FROM perseus.goo
GROUP BY goo_id
HAVING COUNT(*) > 1;  -- Should return 0 rows

-- 5. Critical data present (P0 tables)
SELECT
    (SELECT COUNT(*) FROM perseus.goo) AS goo_count,
    (SELECT COUNT(*) FROM perseus.goo_type) AS goo_type_count,
    (SELECT COUNT(*) FROM perseus.material_transition) AS material_transition_count,
    (SELECT COUNT(*) FROM perseus.transition_material) AS transition_material_count;
```

---

## Sampling Strategy Details

### Challenge: Maintaining FK Relationships with 15% Sample

**Problem**: If we randomly sample 15% of child table, orphaned rows will occur.

**Solution**: Cascading Sampling Strategy

#### Example: goo → material_transition → transition_material

**Step 1**: Extract 15% of `goo` table (parent)
```sql
SELECT TOP 15 PERCENT * FROM goo ORDER BY NEWID();
-- Result: 15,000 goo_ids (out of 100,000)
```

**Step 2**: Extract `material_transition` rows that reference sampled goo_ids
```sql
SELECT * FROM material_transition
WHERE material_id IN (SELECT uid FROM #temp_goo)  -- FK filter
   OR transition_id IN (SELECT uid FROM #temp_fatsmurf);  -- FK filter
-- Result: May be MORE or LESS than 15% (depends on FK distribution)
```

**Step 3**: Extract `transition_material` rows that reference sampled goo_ids + fatsmurf_ids
```sql
SELECT * FROM transition_material
WHERE transition_id IN (SELECT uid FROM #temp_fatsmurf)  -- FK filter
   OR material_id IN (SELECT uid FROM #temp_goo);  -- FK filter
```

**Result**: All FK relationships are preserved, but child tables may not be exactly 15%.

---

## Alternative Strategy: Pure 15% with FK Filtering

**Approach**: Sample 15% of parent tables, then sample 15% of child tables WITHIN valid FK set.

#### Example: goo (15%) → material_transition (15% of valid subset)

**Step 1**: Sample 15% of `goo`
```sql
SELECT TOP 15 PERCENT * FROM goo ORDER BY NEWID();
-- Result: 15,000 goo_ids
```

**Step 2**: Sample 15% of `material_transition` WHERE material_id IN sampled goo_ids
```sql
WITH valid_transitions AS (
    SELECT * FROM material_transition
    WHERE material_id IN (SELECT uid FROM #temp_goo)
      AND transition_id IN (SELECT uid FROM #temp_fatsmurf)
)
SELECT TOP 15 PERCENT *
FROM valid_transitions
ORDER BY NEWID();
-- Result: ~15% of already-filtered set
```

**Tradeoff**: Less data overall, but maintains 15% ratio more consistently.

**Recommendation**: Use this approach for DEV (cleaner 15% across all tables).

---

## Deliverables

### Scripts to Create

1. **`scripts/data-migration/extract-tier0.sql`** - Extract Tier 0 tables (15%)
2. **`scripts/data-migration/extract-tier1.sql`** - Extract Tier 1 tables (15% with FK filter)
3. **`scripts/data-migration/extract-tier2.sql`** - Extract Tier 2 tables (15% with FK filter)
4. **`scripts/data-migration/extract-tier3.sql`** - Extract Tier 3 tables (15% with FK filter)
5. **`scripts/data-migration/extract-tier4.sql`** - Extract Tier 4 tables (15% with FK filter)
6. **`scripts/data-migration/load-data.sh`** - Load all data in dependency order
7. **`scripts/data-migration/validate-referential-integrity.sql`** - FK validation
8. **`scripts/data-migration/validate-row-counts.sql`** - Row count comparison
9. **`scripts/data-migration/validate-checksums.sql`** - Data integrity check
10. **`scripts/data-migration/README.md`** - Complete usage guide

### Documentation to Create

1. **`docs/DATA-MIGRATION-EXECUTION-LOG.md`** - Record of actual migration
2. **`docs/DATA-SAMPLING-REPORT.md`** - Final row counts and percentages

---

## Execution Timeline (Estimated)

| Task | Duration | Notes |
|------|----------|-------|
| **T126: Extract SQL Server data** | 45-60 min | Network latency dependent |
| **T127: Create migration scripts** | 30-45 min | Script development |
| **T128: Load data to PostgreSQL** | 30-45 min | Dependency-ordered load |
| **T129: Row count validation** | 10-15 min | Automated queries |
| **T130: Checksum validation** | 15-20 min | Sample-based validation |
| **T131: Final validation** | 10-15 min | Comprehensive checks |
| **Total** | **2h 20m - 3h 40m** | **~3 hours average** |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| FK violations during load | HIGH | Load in strict dependency order |
| Orphaned child rows | HIGH | Use FK filtering in extraction |
| Data type mismatches | MEDIUM | Pre-validate data types in extraction |
| Network timeouts (SQL Server) | MEDIUM | Extract to intermediate files |
| Sampling not exactly 15% | LOW | Acceptable for DEV (13-17% OK) |
| Performance degradation | LOW | DEV environment, smaller dataset |

---

## Success Criteria

- ✅ **Row Counts**: All tables have 13-17% of production rows (±2% tolerance)
- ✅ **Referential Integrity**: ZERO orphaned FK rows
- ✅ **Data Integrity**: 100% checksum match for sampled rows
- ✅ **PK Uniqueness**: ZERO duplicate primary keys
- ✅ **NULL Validation**: ZERO NULL values in NOT NULL columns
- ✅ **Constraint Violations**: ZERO CHECK constraint violations

---

## Next Steps After Data Migration

1. **Run Query Performance Tests** (T132-T138)
   - Lineage queries (mcgetupstream, mcgetdownstream)
   - Material searches
   - Container tracking queries

2. **Validate Views/Functions** (US1, US2)
   - Create views using loaded data
   - Test function execution with real data

3. **Performance Baseline** (T147-T149)
   - EXPLAIN ANALYZE critical queries
   - Compare with SQL Server performance
   - Verify ±20% performance target

---

**Document Version**: 1.0
**Status**: Plan ready for execution
**Approval Required**: SQL Server access credentials, network access
