# Constraint Deployment Order - Perseus Database Migration

## Executive Summary

**Total Constraints:** 271
- **Primary Keys:** ~95 (mostly in table DDL already)
- **Foreign Keys:** 124 (CRITICAL - dependency order required)
- **Unique:** ~40 (business logic uniqueness)
- **Check:** ~12 (domain validation)

**Deployment Time:** ~15-30 minutes (depending on data volume)

**Risk Level:** MEDIUM-HIGH
- FK constraints require existing parent records (may fail if orphaned data exists)
- CASCADE DELETE constraints (28) can delete large amounts of data
- UID-based FKs require unique indexes on goo.uid and fatsmurf.uid

---

## Pre-Deployment Checklist

### 1. Verify Table Creation Complete

```sql
-- Check all 95 tables exist
SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema IN ('perseus', 'hermes', 'demeter')
  AND table_type = 'BASE TABLE';
-- Expected: 95+ tables
```

### 2. Verify UNIQUE Indexes on UID Columns

```sql
-- CRITICAL: These MUST exist before FK constraints
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'perseus'
  AND indexname IN ('idx_goo_uid', 'idx_fatsmurf_uid');
-- Expected: 2 rows (both indexes exist)
```

### 3. Check for Orphaned Data (FK Pre-Validation)

```sql
-- Check for goo records with invalid goo_type_id
SELECT COUNT(*) AS orphaned_goo
FROM perseus.goo g
WHERE NOT EXISTS (
    SELECT 1 FROM perseus.goo_type gt WHERE gt.id = g.goo_type_id
);
-- Expected: 0 (no orphans)

-- Check for goo records with invalid added_by
SELECT COUNT(*) AS orphaned_goo_users
FROM perseus.goo g
WHERE NOT EXISTS (
    SELECT 1 FROM perseus.perseus_user u WHERE u.id = g.added_by
);
-- Expected: 0 (no orphans)

-- Check for material_transition with invalid goo.uid references
SELECT COUNT(*) AS orphaned_material_transition_goo
FROM perseus.material_transition mt
WHERE NOT EXISTS (
    SELECT 1 FROM perseus.goo g WHERE g.uid = mt.material_id
);
-- Expected: 0 (no orphans)

-- Check for material_transition with invalid fatsmurf.uid references
SELECT COUNT(*) AS orphaned_material_transition_fatsmurf
FROM perseus.material_transition mt
WHERE NOT EXISTS (
    SELECT 1 FROM perseus.fatsmurf f WHERE f.uid = mt.transition_id
);
-- Expected: 0 (no orphans)
```

### 4. Backup Current State

```bash
# Create backup before adding constraints
pg_dump -d perseus_dev -n perseus -n hermes -n demeter \
  --schema-only -f perseus_pre_constraints_schema_backup.sql

# Optional: Full backup with data
pg_dump -d perseus_dev -n perseus -n hermes -n demeter \
  -f perseus_pre_constraints_full_backup.sql
```

---

## Deployment Sequence

### Phase 1: Primary Key Constraints (T120)

**File:** `01-primary-key-constraints.sql`

**Action:** Most PKs already in table DDL - just verify

```bash
psql -d perseus_dev -f 01-primary-key-constraints.sql
```

**Expected Output:**
- "SUCCESS: All tables have PRIMARY KEY constraints defined."

**Validation:**
```sql
-- Verify all tables have PKs
SELECT table_schema, table_name
FROM information_schema.tables t
WHERE t.table_schema IN ('perseus', 'hermes', 'demeter')
  AND t.table_type = 'BASE TABLE'
  AND NOT EXISTS (
      SELECT 1
      FROM information_schema.table_constraints tc
      WHERE tc.table_schema = t.table_schema
        AND tc.table_name = t.table_name
        AND tc.constraint_type = 'PRIMARY KEY'
  );
-- Expected: 0 rows (all tables have PKs)
```

**Rollback:** N/A (PKs already in table DDL)

---

### Phase 2: Foreign Key Constraints (T121) - CRITICAL PHASE

**File:** `02-foreign-key-constraints.sql`

**Action:** Create all 124 FK constraints in dependency order

**IMPORTANT:** This file MUST be executed as a single transaction OR in dependency order:
- Tier 1 FKs → Tier 2 FKs → Tier 3 FKs → Tier 4 FKs

```bash
# Method 1: Single transaction (recommended for DEV)
psql -d perseus_dev -v ON_ERROR_STOP=1 << 'EOF'
BEGIN;
\i 02-foreign-key-constraints.sql
COMMIT;
EOF

# Method 2: Execute file directly (auto-commits each statement)
psql -d perseus_dev -f 02-foreign-key-constraints.sql
```

**Expected Output:**
- "ALTER TABLE" for each constraint (124 statements)
- No errors (all parent records exist)

**Common Errors:**

1. **FK Violation (orphaned data):**
   ```
   ERROR: insert or update on table "goo" violates foreign key constraint "goo_fk_1"
   DETAIL: Key (goo_type_id)=(99999) is not present in table "goo_type".
   ```
   **Fix:** Clean up orphaned data before re-running:
   ```sql
   -- Delete orphaned goo records
   DELETE FROM perseus.goo
   WHERE goo_type_id NOT IN (SELECT id FROM perseus.goo_type);
   ```

2. **Missing Unique Index:**
   ```
   ERROR: there is no unique constraint matching given keys for referenced table "goo"
   ```
   **Fix:** Create unique index:
   ```sql
   CREATE UNIQUE INDEX idx_goo_uid ON perseus.goo(uid);
   ```

**Validation:**
```sql
-- Verify all 124 FK constraints created
SELECT COUNT(*) AS fk_count
FROM information_schema.table_constraints
WHERE constraint_schema IN ('perseus', 'hermes', 'demeter')
  AND constraint_type = 'FOREIGN KEY';
-- Expected: 124

-- Verify P0 critical FKs exist
SELECT constraint_name, table_name
FROM information_schema.table_constraints
WHERE constraint_schema = 'perseus'
  AND constraint_type = 'FOREIGN KEY'
  AND constraint_name IN (
      'fk_material_transition_goo',
      'fk_material_transition_fatsmurf',
      'fk_transition_material_goo',
      'fk_transition_material_fatsmurf'
  )
ORDER BY constraint_name;
-- Expected: 4 rows
```

**Rollback:**
```sql
-- Drop all FK constraints in reverse dependency order
-- See: rollback-foreign-keys.sql (generated separately)
```

---

### Phase 3: Unique Constraints (T122)

**File:** `03-unique-constraints.sql`

**Action:** Create ~40 unique constraints

```bash
psql -d perseus_dev -f 03-unique-constraints.sql
```

**Expected Output:**
- "ALTER TABLE" for each constraint (~40 statements)
- No errors (no duplicate data)

**Common Errors:**

1. **Duplicate Values:**
   ```
   ERROR: could not create unique index "uq_goo_type_name"
   DETAIL: Key (name)=(Plasmid) is duplicated.
   ```
   **Fix:** Clean up duplicates:
   ```sql
   -- Find duplicates
   SELECT name, COUNT(*)
   FROM perseus.goo_type
   GROUP BY name
   HAVING COUNT(*) > 1;

   -- Resolve duplicates (merge or delete)
   ```

**Validation:**
```sql
-- Verify all UNIQUE constraints created
SELECT COUNT(*) AS unique_count
FROM information_schema.table_constraints
WHERE constraint_schema IN ('perseus', 'hermes', 'demeter')
  AND constraint_type = 'UNIQUE';
-- Expected: ~40

-- Test: Try inserting duplicate (should fail)
INSERT INTO perseus.goo_type (name, abbreviation, hierarchy_left, hierarchy_right)
VALUES ('Plasmid', 'TEST', 1, 2);
-- Expected: ERROR - duplicate key value violates unique constraint
```

**Rollback:**
```sql
-- Drop unique constraints (if needed)
ALTER TABLE perseus.goo_type DROP CONSTRAINT uq_goo_type_name;
ALTER TABLE perseus.goo_type DROP CONSTRAINT uq_goo_type_abbreviation;
-- ... (repeat for all unique constraints)
```

---

### Phase 4: Check Constraints (T123)

**File:** `04-check-constraints.sql`

**Action:** Create ~12 check constraints

```bash
psql -d perseus_dev -f 04-check-constraints.sql
```

**Expected Output:**
- "ALTER TABLE" for each constraint (~12 statements)
- No errors (existing data passes validation)

**Common Errors:**

1. **Existing Data Violates Check:**
   ```
   ERROR: check constraint "chk_material_inventory_quantity_nonnegative" is violated by some row
   ```
   **Fix:** Clean up invalid data:
   ```sql
   -- Find invalid data
   SELECT * FROM perseus.material_inventory WHERE quantity < 0;

   -- Fix invalid data
   UPDATE perseus.material_inventory SET quantity = 0 WHERE quantity < 0;
   ```

**Validation:**
```sql
-- Verify all CHECK constraints created
SELECT COUNT(*) AS check_count
FROM information_schema.table_constraints
WHERE constraint_schema IN ('perseus', 'hermes', 'demeter')
  AND constraint_type = 'CHECK';
-- Expected: ~12

-- Test: Try inserting invalid value (should fail)
INSERT INTO perseus.material_inventory (material_id, recipe_id, quantity, volume, mass, created_by_id, updated_by_id)
VALUES (1, 1, -10, 0, 0, 1, 1);
-- Expected: ERROR - new row violates check constraint
```

**Rollback:**
```sql
-- Drop check constraints (if needed)
ALTER TABLE perseus.material_inventory DROP CONSTRAINT chk_material_inventory_quantity_nonnegative;
-- ... (repeat for all check constraints)
```

---

### Phase 5: Test Constraint Enforcement (T125)

**File:** `05-constraint-test-cases.sql`

**Action:** Run comprehensive test suite (all tests expected to FAIL with constraint violations)

```bash
psql -d perseus_dev -f 05-constraint-test-cases.sql
```

**Expected Output:**
- Multiple "PASS" messages (constraints working correctly)
- Multiple "FAIL" messages if constraints not enforced

**Example Output:**
```
NOTICE: ======================================
NOTICE: FOREIGN KEY CONSTRAINT TESTS
NOTICE: ======================================
NOTICE: PASS: FK-001: goo invalid goo_type_id - Foreign key violation as expected (goo_fk_1)
NOTICE: PASS: FK-002: goo invalid added_by - Foreign key violation as expected (goo_fk_4)
...
```

**Validation:**
- Review output for any "FAIL" messages
- Investigate any failures (constraint not working)

**Rollback:** N/A (test suite runs in transaction, auto-rolls back)

---

## Post-Deployment Validation

### 1. Constraint Count Summary

```sql
SELECT
    constraint_type,
    COUNT(*) AS constraint_count
FROM information_schema.table_constraints
WHERE constraint_schema IN ('perseus', 'hermes', 'demeter')
GROUP BY constraint_type
ORDER BY constraint_type;
```

**Expected:**
```
constraint_type  | constraint_count
-----------------+-----------------
CHECK            |              12
FOREIGN KEY      |             124
PRIMARY KEY      |              95
UNIQUE           |              40
```

### 2. Verify P0 Critical Constraints

```sql
-- Material lineage FKs (MUST exist)
SELECT constraint_name, table_name, constraint_type
FROM information_schema.table_constraints
WHERE constraint_schema = 'perseus'
  AND table_name IN ('material_transition', 'transition_material')
  AND constraint_type = 'FOREIGN KEY'
ORDER BY table_name, constraint_name;
-- Expected: 4 rows (2 FKs per table)
```

### 3. Test Basic Operations

```sql
-- Test: Insert valid goo record (should succeed)
INSERT INTO perseus.goo (uid, name, goo_type_id, added_by, manufacturer_id)
VALUES ('TEST-VALIDATION-001', 'Test Material', 8, 1, 1);

-- Test: Insert invalid goo_type_id (should fail)
INSERT INTO perseus.goo (uid, name, goo_type_id, added_by, manufacturer_id)
VALUES ('TEST-VALIDATION-002', 'Test Material', 99999, 1, 1);
-- Expected: ERROR - violates foreign key constraint "goo_fk_1"

-- Rollback test data
ROLLBACK;
```

---

## Troubleshooting Guide

### Problem: FK constraint fails due to orphaned data

**Symptom:**
```
ERROR: insert or update on table "X" violates foreign key constraint "fk_X_Y"
```

**Solution:**
```sql
-- Find orphaned records
SELECT child_table.*
FROM perseus.child_table child_table
WHERE NOT EXISTS (
    SELECT 1 FROM perseus.parent_table parent_table
    WHERE parent_table.id = child_table.parent_id
);

-- Clean up orphans (CAREFUL - may lose data)
DELETE FROM perseus.child_table
WHERE parent_id NOT IN (SELECT id FROM perseus.parent_table);
```

### Problem: UNIQUE constraint fails due to duplicates

**Symptom:**
```
ERROR: could not create unique index "uq_X_Y"
DETAIL: Key (Y)=(value) is duplicated.
```

**Solution:**
```sql
-- Find duplicates
SELECT column_name, COUNT(*)
FROM perseus.table_name
GROUP BY column_name
HAVING COUNT(*) > 1;

-- Resolve duplicates (business logic decision required)
-- Option 1: Merge records
-- Option 2: Delete duplicates
-- Option 3: Update duplicate values
```

### Problem: CHECK constraint fails due to invalid existing data

**Symptom:**
```
ERROR: check constraint "chk_X_Y" is violated by some row
```

**Solution:**
```sql
-- Find invalid rows
SELECT * FROM perseus.table_name
WHERE NOT (check_condition);

-- Fix invalid data
UPDATE perseus.table_name
SET column_name = valid_value
WHERE NOT (check_condition);
```

---

## Rollback Procedures

### Full Rollback (Drop All Constraints)

```sql
-- Drop all CHECK constraints
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT constraint_schema, table_name, constraint_name
        FROM information_schema.table_constraints
        WHERE constraint_schema IN ('perseus', 'hermes', 'demeter')
          AND constraint_type = 'CHECK'
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I',
            r.constraint_schema, r.table_name, r.constraint_name);
    END LOOP;
END $$;

-- Drop all UNIQUE constraints
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT constraint_schema, table_name, constraint_name
        FROM information_schema.table_constraints
        WHERE constraint_schema IN ('perseus', 'hermes', 'demeter')
          AND constraint_type = 'UNIQUE'
          AND constraint_name NOT LIKE 'idx_%' -- Keep UID indexes
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I',
            r.constraint_schema, r.table_name, r.constraint_name);
    END LOOP;
END $$;

-- Drop all FK constraints (in reverse dependency order)
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Tier 4 first
    FOR r IN
        SELECT constraint_schema, table_name, constraint_name
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'perseus'
          AND constraint_type = 'FOREIGN KEY'
          AND table_name IN (
              'material_inventory_threshold_notify_user',
              'submission_entry',
              'robot_log_transfer',
              'robot_log_read',
              'robot_log_error',
              'robot_log_container_sequence',
              'poll_history',
              'transition_material',
              'material_transition',
              'material_qc',
              'material_inventory_threshold',
              'material_inventory',
              'goo_history',
              'goo_comment',
              'goo_attachment',
              'fatsmurf_history',
              'fatsmurf_comment',
              'fatsmurf_attachment'
          )
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I',
            r.constraint_schema, r.table_name, r.constraint_name);
    END LOOP;

    -- Tier 3, 2, 1 (continue pattern for all tiers)
    -- ... (complete list in separate rollback script)
END $$;
```

### Partial Rollback (Single Constraint)

```sql
-- Drop single FK constraint
ALTER TABLE perseus.goo DROP CONSTRAINT goo_fk_1;

-- Drop single UNIQUE constraint
ALTER TABLE perseus.goo_type DROP CONSTRAINT uq_goo_type_name;

-- Drop single CHECK constraint
ALTER TABLE perseus.material_inventory DROP CONSTRAINT chk_material_inventory_quantity_nonnegative;
```

---

## Performance Considerations

### Constraint Creation Performance

- **PRIMARY KEY:** Instant (already in table DDL)
- **FOREIGN KEY:** ~10-30 seconds per constraint (depends on table size)
- **UNIQUE:** ~5-15 seconds per constraint (creates index)
- **CHECK:** Instant (inline validation)

**Total Estimated Time:** 15-30 minutes for all 271 constraints

### Impact on Future Operations

- **INSERT:** +5-10% overhead (FK + CHECK validation)
- **UPDATE:** +5-15% overhead (FK + UNIQUE + CHECK validation)
- **DELETE:** Variable (CASCADE DELETE can be slow)
- **SELECT:** Improved (UNIQUE constraints create indexes)

---

## Success Criteria

- [ ] All 95 PRIMARY KEY constraints exist (verified)
- [ ] All 124 FOREIGN KEY constraints created without errors
- [ ] All ~40 UNIQUE constraints created without errors
- [ ] All ~12 CHECK constraints created without errors
- [ ] Test suite passes (all constraint violations correctly raised)
- [ ] P0 critical constraints validated (material lineage FKs)
- [ ] No orphaned data detected
- [ ] Performance acceptable (<30 min total deployment)

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | 2026-01-26 |
| Author | Claude (Database Expert Agent) |
| Total Constraints | 271 |
| Estimated Deployment Time | 15-30 minutes |
| Risk Level | MEDIUM-HIGH |
| Dependencies | Tables (T114-T119), Indexes (T108-T113) |
