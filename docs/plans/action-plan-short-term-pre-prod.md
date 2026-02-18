# Action Plan: Short-Term (Pre-PROD)

**User Story:** US3 - Table Structures
**Priority:** P1-P2 actions required before PRODUCTION deployment
**Estimated Effort:** 8-12 hours
**Created:** 2026-02-13

---

## 1. Regenerate Index Files from Deployed Schema (P1)

**Problem:** AWS SCT-generated index files contain stale column references that don't match the deployed table schema. Manual fixes are error-prone; a schema-driven regeneration ensures accuracy.

**Steps:**

1. Query `pg_indexes` for all currently deployed indexes:
   ```sql
   SELECT schemaname, tablename, indexname, indexdef
   FROM pg_indexes
   WHERE schemaname = 'perseus'
   ORDER BY tablename, indexname;
   ```

2. Query `information_schema.columns` for the complete column inventory:
   ```sql
   SELECT table_name, column_name, data_type, ordinal_position
   FROM information_schema.columns
   WHERE table_schema = 'perseus'
   ORDER BY table_name, ordinal_position;
   ```

3. For each undeployed index (38 remaining), compare the index DDL against the column inventory.

4. Generate corrected index DDL that references only existing columns.

5. Replace the affected files in `source/building/pgsql/refactored/16. create-index/`.

6. Deploy and verify:
   ```sql
   SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'perseus';
   -- Target: 213
   ```

**Acceptance Criteria:**
- 100% index deployment (213/213)
- All index files match the deployed table schema
- No column mismatch errors

---

## 2. Add Column Existence Validation Script (P1)

**Problem:** No automated check exists to verify that index/constraint files reference valid columns before deployment.

**Deliverable:** `scripts/validation/validate-columns.sh`

**Script Requirements:**

1. Parse all `CREATE INDEX` statements and extract referenced column names.
2. Parse all `ALTER TABLE ADD CONSTRAINT` statements and extract referenced column names.
3. Query the deployed schema (or parse CREATE TABLE files) for actual column names.
4. Compare and report mismatches.
5. Exit with non-zero status if any mismatches found.

**Usage:**
```bash
# Validate against deployed schema
./scripts/validation/validate-columns.sh --source docker --database perseus_dev

# Validate against DDL files (no database needed)
./scripts/validation/validate-columns.sh --source files --path source/building/pgsql/refactored/
```

**Acceptance Criteria:**
- Script runs successfully and catches known column mismatches
- Integrated into pre-deployment checklist
- Documented in `docs/deployment-guide.md`

---

## 3. Create Idempotent Constraint Scripts (P2)

**Problem:** Constraint scripts fail on re-runs with "already exists" errors because they lack idempotency guards.

**Approach:** Wrap each constraint in a `DO` block with exception handling:

```sql
DO $$
BEGIN
    ALTER TABLE perseus.table_name
        ADD CONSTRAINT constraint_name FOREIGN KEY (column_name)
        REFERENCES perseus.other_table (id);
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'Constraint constraint_name already exists, skipping.';
END $$;
```

**Alternative approach (simpler):**
```sql
ALTER TABLE perseus.table_name
    DROP CONSTRAINT IF EXISTS constraint_name;
ALTER TABLE perseus.table_name
    ADD CONSTRAINT constraint_name FOREIGN KEY (column_name)
    REFERENCES perseus.other_table (id);
```

**Steps:**

1. Choose approach (recommend `DROP IF EXISTS` + `ADD` for simplicity and atomicity).
2. Apply pattern to all constraint files in `17-18. constraints/`.
3. Test by running constraint scripts twice — second run should produce no errors.

**Acceptance Criteria:**
- All constraint scripts can be run multiple times without errors
- No data loss or constraint gaps from re-runs
- Pattern documented for future constraint files

---

## 4. Pre-Deployment Reserved Word Checker (P2)

**Problem:** Reserved word conflicts (like `offset`) are only discovered at deployment time, causing unexpected failures.

**Deliverable:** `scripts/validation/check-reserved-words.sh`

**Script Requirements:**

1. Maintain a list of PostgreSQL reserved words (extracted from `pg_get_keywords()` where `catcode IN ('R', 'T')`).
2. Parse all DDL files for column names, table names, and alias names.
3. Flag any identifiers that match reserved words and are not quoted.
4. Output a report with file path, line number, and the offending identifier.
5. Exit with non-zero status if any unquoted reserved words found.

**Usage:**
```bash
./scripts/validation/check-reserved-words.sh source/building/pgsql/refactored/
```

**Example output:**
```
WARNING: Reserved word found unquoted
  File: 14. create-table/fatsmurf.sql:15
  Column: "offset" (reserved word, category: reserved)
  Fix: Quote as "offset"

Found 1 unquoted reserved word(s). Please fix before deployment.
```

**Acceptance Criteria:**
- Script detects the known `offset` case
- Can be run as a pre-deployment gate
- Documented in deployment guide

---

## Tracking

| # | Task | Priority | Status |
|---|------|----------|--------|
| 1 | Regenerate index files from schema | P1 | Pending |
| 2 | Column existence validation script | P1 | Pending |
| 3 | Idempotent constraint scripts | P2 | Pending |
| 4 | Reserved word checker script | P2 | Pending |
