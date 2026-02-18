# Action Plan: Immediate (Pre-STAGING)

**User Story:** US3 - Table Structures
**Priority:** P1-P2 actions required before STAGING deployment
**Estimated Effort:** 4-6 hours
**Created:** 2026-02-13

---

## 1. Fix ~40 Column Name Mismatches (P1)

**Problem:** ~40 index and constraint files reference columns that don't exist in the deployed table DDL. Root cause: AWS SCT naming transformations were inconsistent with manual refactoring decisions.

**Impact:** 38 indexes and ~40 constraints failed to deploy (column mismatch errors).

**Steps:**

1. Query deployed schema for actual column names per table:
   ```sql
   SELECT table_name, column_name
   FROM information_schema.columns
   WHERE table_schema = 'perseus'
   ORDER BY table_name, ordinal_position;
   ```

2. For each failed index/constraint file, compare referenced columns against the query results.

3. Update the SQL files to use the correct column names.

4. Redeploy the fixed indexes and constraints:
   ```bash
   docker exec -i perseus-postgres psql -U postgres -d perseus_dev < <fixed-file>.sql
   ```

5. Verify deployment:
   ```sql
   SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'perseus';
   SELECT conname, contype FROM pg_constraint c
   JOIN pg_namespace n ON c.connamespace = n.oid
   WHERE n.nspname = 'perseus';
   ```

**Acceptance Criteria:**
- All 213 indexes deployed successfully (currently 175/213)
- All 270 constraints deployed successfully (currently 230/270)
- Zero column mismatch errors

---

## 2. Fix 2 TABLESPACE Syntax Errors (P1)

**Problem:** Two indexes in `16. create-index/03-query-optimization-indexes.sql` have invalid TABLESPACE clauses.

**Steps:**

1. Open `source/building/pgsql/refactored/16. create-index/03-query-optimization-indexes.sql`
2. Locate TABLESPACE references
3. Either remove TABLESPACE clauses (use default) or correct the tablespace name
4. Redeploy the affected indexes

**Acceptance Criteria:**
- Both indexes deploy without syntax errors
- Indexes appear in `pg_indexes` catalog

---

## 3. Audit Reserved Words (P2)

**Problem:** PostgreSQL reserved word `offset` was used unquoted as a column name, causing deployment failures. AWS SCT does NOT handle reserved word quoting.

**Steps:**

1. Get full reserved word list:
   ```sql
   SELECT word FROM pg_get_keywords() WHERE catcode IN ('R', 'T')
   ORDER BY word;
   ```

2. Search all DDL files for unquoted reserved words:
   ```bash
   # Extract column names from all CREATE TABLE files
   grep -oP '^\s+\K\w+(?=\s+(INTEGER|BIGINT|TEXT|VARCHAR|BOOLEAN|TIMESTAMP|NUMERIC|SMALLINT|UUID|BYTEA|DATE))' \
     source/building/pgsql/refactored/14.\ create-table/*.sql
   ```

3. Cross-reference extracted column names against the reserved word list.

4. Quote any matches with double quotes (e.g., `offset` -> `"offset"`).

5. Propagate quoting changes to all index/constraint files referencing those columns.

**Acceptance Criteria:**
- All column names checked against `pg_get_keywords()`
- Any reserved words properly quoted in table, index, and constraint files
- No reserved word errors on redeployment

---

## 4. Document Expected Errors in Deployment Guide (P3)

**Problem:** Several error categories during US3 deployment were expected/harmless but not documented, causing confusion.

**Steps:**

1. Create `docs/deployment-guide.md` documenting:

   - **FDW Schema Errors (Expected):** Foreign Data Wrapper tables reference remote schemas (hermes, sqlapps, deimeter) not available in DEV/STAGING. These errors are expected and harmless in non-production environments.

   - **Materialized View Errors (Expected):** The `translated` materialized view depends on functions from US4/US5. Will fail until those user stories are complete. Not a blocker for US3.

   - **Non-Idempotent Constraints:** Constraint scripts use `ALTER TABLE ADD CONSTRAINT` without `IF NOT EXISTS` guards. Re-running produces "already exists" errors that are harmless but noisy. See Short-Term Plan for idempotent fix.

   - **Permission Denied in Docker:** Compound commands (`&&`) in `docker exec` context may produce false "permission denied" errors. Use simple single-statement commands piped to `docker exec psql` instead.

**Acceptance Criteria:**
- `docs/deployment-guide.md` exists with all four sections
- Team members can distinguish expected vs unexpected errors

---

## Tracking

| # | Task | Priority | Status |
|---|------|----------|--------|
| 1 | Fix column name mismatches | P1 | Pending |
| 2 | Fix TABLESPACE syntax errors | P1 | Pending |
| 3 | Audit reserved words | P2 | Pending |
| 4 | Document expected errors | P3 | Pending |
