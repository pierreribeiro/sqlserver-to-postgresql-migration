# Action Plan: Long-Term (Process Improvement)

**User Story:** US3 - Table Structures (lessons applied project-wide)
**Priority:** P2-P3 process improvements for remaining migration phases
**Estimated Effort:** 16-24 hours (spread across future sprints)
**Created:** 2026-02-13

---

## 1. Automated Schema Drift Detection (P2)

**Problem:** DDL files in the repository can drift from the actual deployed database schema over time, especially as manual fixes are applied during deployment. There is currently no way to detect or reconcile this drift.

**Deliverable:** `scripts/validation/detect-schema-drift.sh`

**Requirements:**

1. **Extract file-based schema:** Parse all CREATE TABLE files to build an expected schema model (table names, column names, data types, constraints).

2. **Extract deployed schema:** Query `information_schema.columns`, `pg_indexes`, and `pg_constraint` to build the actual schema model.

3. **Compare and report:**
   - Columns in files but not in DB (missing deployments)
   - Columns in DB but not in files (undocumented changes)
   - Data type mismatches between file and DB
   - Index definitions that differ between file and DB

4. **Output:** Structured drift report (markdown or JSON) with actionable fix suggestions.

**Usage:**
```bash
./scripts/validation/detect-schema-drift.sh \
  --ddl-path source/building/pgsql/refactored/ \
  --database perseus_dev \
  --output docs/reports/schema-drift-report.md
```

**Acceptance Criteria:**
- Detects known US3 drift cases (column renames, type changes)
- Runs in under 60 seconds for full schema comparison
- Can be scheduled (cron) or run manually

---

## 2. Integration Tests: Index/Constraint vs Table DDL (P2)

**Problem:** Column name mismatches between table DDL and index/constraint DDL are the #1 source of deployment failures in US3. These can be caught without a database by pure file analysis.

**Deliverable:** `scripts/validation/validate-ddl-consistency.sh` (or Python equivalent)

**Requirements:**

1. **Parse CREATE TABLE files:** Extract table name and all column names per table.

2. **Parse CREATE INDEX files:** Extract index name, target table, and referenced columns.

3. **Parse ALTER TABLE ADD CONSTRAINT files:** Extract constraint name, target table, and referenced columns.

4. **Cross-validate:**
   - Every column in an index must exist in the corresponding table DDL
   - Every column in a constraint must exist in the corresponding table DDL
   - Report mismatches with file paths and line numbers

5. **No database required** — pure file-based validation.

**Usage:**
```bash
./scripts/validation/validate-ddl-consistency.sh \
  --tables "source/building/pgsql/refactored/14. create-table/" \
  --indexes "source/building/pgsql/refactored/16. create-index/" \
  --constraints "source/building/pgsql/refactored/17. create-constraint/"
```

**Acceptance Criteria:**
- Catches all 40+ column mismatches identified in US3 deployment
- Runs without database connectivity (CI-friendly)
- Produces clear, actionable output

---

## 3. Enhanced AWS SCT Post-Processing (P3)

**Problem:** AWS SCT output requires significant manual correction. Key issues seen in US3:
- Reserved words not quoted (`offset`, `position`, etc.)
- Inconsistent PascalCase → snake_case transformations
- Column names in index/constraint files don't match table files
- TIMESTAMP not converted to TIMESTAMPTZ for local tables

**Deliverable:** `scripts/automation/sct-post-processor.py`

**Requirements:**

1. **Reserved Word Quoting:**
   - Load PostgreSQL reserved word list
   - Scan all identifiers in SCT output
   - Auto-quote reserved words with double quotes

2. **Naming Standardization:**
   - Apply consistent PascalCase → snake_case rules (per `docs/naming-conversion-rules.md`)
   - Ensure the same column name transformation is applied across table, index, and constraint files

3. **Type Corrections:**
   - Convert `TIMESTAMP` → `TIMESTAMPTZ` for local tables
   - Skip conversion for FOREIGN TABLE definitions
   - Apply other known type mappings (per CLAUDE.md transformation table)

4. **Cross-File Consistency:**
   - After transforming column names in table files, propagate changes to index and constraint files
   - Report any references that couldn't be resolved

**Usage:**
```bash
python scripts/automation/sct-post-processor.py \
  --input source/original/pgsql-aws-sct-converted/ \
  --output source/building/pgsql/refactored/ \
  --rules docs/naming-conversion-rules.md
```

**Acceptance Criteria:**
- Eliminates reserved word deployment failures
- Column names consistent across table/index/constraint files
- Reduces manual correction effort by 50%+

---

## 4. CI/CD Pipeline Integration (P3)

**Problem:** All validation is currently manual. As the project scales to 769 objects across multiple user stories, manual validation becomes a bottleneck and error-prone.

**Deliverable:** GitHub Actions workflow(s)

**Requirements:**

1. **PR Validation Workflow** (`.github/workflows/validate-ddl.yml`):
   - Trigger: On PRs that modify `source/building/pgsql/refactored/`
   - Steps:
     - Run DDL consistency checker (Task 2)
     - Run reserved word checker (Short-Term Plan, Task 4)
     - Run schema drift detection against a reference schema
   - Block merge if P0/P1 validation failures

2. **Deployment Validation Workflow** (`.github/workflows/validate-deployment.yml`):
   - Trigger: On merge to deployment branches
   - Steps:
     - Spin up PostgreSQL 17 container
     - Deploy all DDL files in dependency order (0-21)
     - Capture and report any deployment errors
     - Run column existence validation
   - Report results as PR comment

3. **Nightly Schema Drift Check** (`.github/workflows/nightly-drift.yml`):
   - Trigger: Scheduled (nightly)
   - Steps:
     - Compare repository DDL against DEV database schema
     - Generate drift report
     - Create GitHub issue if drift detected

**Acceptance Criteria:**
- PRs with column mismatches are blocked automatically
- Deployment errors are caught before reaching STAGING
- Schema drift detected within 24 hours

---

## Dependency Graph

```
Task 2 (DDL Consistency) ─────────┐
                                   ├──► Task 4 (CI/CD Pipeline)
Task 3 (SCT Post-Processing) ─────┘
                                        │
Task 1 (Schema Drift Detection) ────────┘
```

Tasks 1-3 can be developed independently. Task 4 integrates all three into CI/CD.

---

## Tracking

| # | Task | Priority | Status | Sprint Target |
|---|------|----------|--------|---------------|
| 1 | Schema drift detection | P2 | Pending | Sprint 5 |
| 2 | DDL consistency tests | P2 | Pending | Sprint 5 |
| 3 | SCT post-processing | P3 | Pending | Sprint 6 |
| 4 | CI/CD integration | P3 | Pending | Sprint 7 |
