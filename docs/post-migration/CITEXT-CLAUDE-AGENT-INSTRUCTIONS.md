# CITEXT Conversion -- Claude Agent Instructions for Procedure/Function Updates

**Purpose:** Instructions for a Claude agent session to update stored procedures and functions after the US7 CITEXT column conversion.
**Created:** 2026-03-17
**Prerequisite:** US7 (column conversion) must be fully deployed and US2 (function conversion) should be complete or in progress.

---

## 1. Context: What US7 Did

US7 converted **172 VARCHAR columns to CITEXT** across 65+ tables in the Perseus PostgreSQL database. CITEXT is a case-insensitive text type provided by the `citext` extension. After US7:

- All `uid`, `name`, `description`, `material_id`, `transition_id`, `path`, `start_point`, `end_point`, and similar identifier/label columns are now CITEXT
- All 22 views were dropped and recreated with updated column types
- All affected indexes and constraints were dropped and recreated
- The `translated` materialized view was updated (casts changed from `::VARCHAR(50)` to `::CITEXT`)

**What was NOT done in US7:**
- Stored procedure parameter types, variable declarations, and explicit casts were NOT updated
- Function parameter types, return types, variable declarations were NOT updated
- The 25 functions have not yet been converted to PostgreSQL at all (US2 scope)

---

## 2. Scope of This Work

### Procedures (15 files)
Update existing PostgreSQL procedure files in `source/building/pgsql/refactored/20.create-procedure/`:
- Change VARCHAR parameters to CITEXT where they reference converted columns
- Change VARCHAR variable declarations to CITEXT where they store values from converted columns
- Replace `::VARCHAR` casts with `::CITEXT` where casting to/from converted columns
- Keep VARCHAR for variables that store non-CITEXT values (table names, error messages, etc.)

### Functions (25 functions)
When converting functions from SQL Server to PostgreSQL (US2), incorporate CITEXT types from the start:
- Use CITEXT for parameters that accept uid, name, material_id, transition_id, path values
- Use CITEXT for return table columns that correspond to converted table columns
- Use CITEXT for local variables storing values from converted columns

---

## 3. Step-by-Step Workflow

### Phase 0: Preparation

```
0.1  Read the two companion guide documents:
     - docs/post-migration/CITEXT-PROCEDURES-UPDATE-GUIDE.md
     - docs/post-migration/CITEXT-FUNCTIONS-UPDATE-GUIDE.md

0.2  Read the CITEXT candidate list to understand which columns changed:
     - prompts/columns_citext_candidates.txt

0.3  Read the dependency analysis:
     - docs/post-migration/citext-dependency-analysis.md
     - docs/code-analysis/dependency/dependency-analysis-lote2-functions.md

0.4  Read the project constitution for coding standards:
     - docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md

0.5  Verify the citext extension is installed:
     psql -d perseus_dev -c "SELECT * FROM pg_extension WHERE extname = 'citext';"
```

### Phase 1: Update Stored Procedures

Process procedures in priority order (P0 first):

```
For each procedure file in source/building/pgsql/refactored/20.create-procedure/:

1.1  Read the current procedure source file completely.

1.2  Cross-reference parameters against the CITEXT columns list:
     - If a parameter name matches or references a CITEXT column (uid, material_id,
       transition_id, name, path, start_point, end_point, etc.), change its type.
     - Example: par_materialuid VARCHAR --> par_materialuid CITEXT

1.3  Cross-reference DECLARE variables against CITEXT columns:
     - If a variable stores values from a CITEXT column, change its type.
     - Example: v_current_uid VARCHAR(50) --> v_current_uid CITEXT
     - DO NOT change: v_error_message TEXT, c_procedure_name VARCHAR, v_target_table VARCHAR

1.4  Find and update explicit casts:
     - Replace ::VARCHAR(50) with ::CITEXT where the value references a converted column.
     - Keep ::VARCHAR for non-CITEXT contexts (e.g., formatting error messages).

1.5  Review temporary table definitions within the procedure:
     - If a temp table has columns that mirror CITEXT table columns, update them.

1.6  Deploy and test:
     psql -d perseus_dev -f <procedure>.sql
     psql -d perseus_dev -f tests/unit/test_<procedure>.sql

1.7  If tests fail, diagnose and fix. Common issues:
     - Type mismatch in function calls (callee still expects VARCHAR)
     - Implicit cast warnings in concatenation operations
     - GooList type uid column type mismatch
```

### Phase 2: Update/Create Functions

Process functions in priority order (McGet* first):

```
For each function:

2.1  Read the original SQL Server source:
     source/original/sqlserver/11.create-routine/<number>.perseus.dbo.<FunctionName>.sql

2.2  Read the AWS SCT baseline (if available):
     source/original/pgsql-aws-sct-converted/19.create-function/<number>.perseus.<name>.sql

2.3  Convert to PostgreSQL following the project constitution, using CITEXT types
     from the start for all parameters and return columns that correspond to
     converted table columns.

2.4  Write the refactored function to:
     source/building/pgsql/refactored/19.create-function/<number>.perseus.<name>.sql

2.5  Deploy and test:
     psql -d perseus_dev -f <function>.sql
     -- Create unit test if not existing:
     tests/unit/views/test_<function>.sql  (or tests/unit/functions/)

2.6  Verify return types match expectations:
     SELECT proname, pg_get_function_result(oid)
     FROM pg_proc
     WHERE proname = '<function_name>';
```

### Phase 3: Integration Testing

```
3.1  Test the full call chain:
     - Call AddArc with CITEXT uid values
     - Verify McGetUpStream returns CITEXT columns
     - Verify ReconcileMUpstream processes correctly
     - Verify m_upstream/m_downstream tables populated correctly

3.2  Test case-insensitive behavior end-to-end:
     - Insert a material with uid 'M12345'
     - Call functions with 'm12345' (lowercase)
     - Verify results are found (case-insensitive matching)

3.3  Run all existing unit tests:
     for f in tests/unit/test_*.sql; do
       psql -d perseus_dev -f "$f"
     done

3.4  Performance validation:
     - Run EXPLAIN ANALYZE on key function calls
     - Compare against baseline (must be within +/-20%)
```

### Phase 4: Documentation and Commit

```
4.1  Update the progress tracker:
     tracking/progress-tracker.md

4.2  Update the activity log:
     tracking/activity-log-YYYY-MM.md

4.3  Commit changes with conventional commit format:
     git add source/building/pgsql/refactored/20.create-procedure/*.sql
     git add source/building/pgsql/refactored/19.create-function/*.sql
     git add tests/unit/
     git commit -m "feat(citext): update procedure/function types for CITEXT columns"
```

---

## 4. Decision Rules

### When to use CITEXT vs VARCHAR

| Context | Use CITEXT | Use VARCHAR | Use TEXT |
|---|---|---|---|
| Parameter referencing `goo.uid` | YES | | |
| Parameter referencing `fatsmurf.uid` | YES | | |
| Parameter for `material_id` / `transition_id` | YES | | |
| Parameter for `name` columns | YES | | |
| Parameter for `path` / `start_point` / `end_point` | YES | | |
| Variable storing error messages | | | YES |
| Variable storing table names | | YES | |
| Variable storing procedure names | | YES | |
| Variable storing SQL strings | | | YES |
| Return column matching a CITEXT table column | YES | | |
| Return column that is a computed label | | | Depends on usage |

### When to add explicit casts

- **FDW boundary:** Always cast foreign table values to CITEXT explicitly: `foreign_col::CITEXT`
- **UUID to identifier:** `gen_random_uuid()::CITEXT` instead of `gen_random_uuid()::VARCHAR`
- **Integer to string:** Use `CAST(int_val AS CITEXT)` or `int_val::CITEXT`
- **Do NOT cast:** CITEXT to CITEXT (redundant), TEXT to CITEXT within same schema (implicit is fine)

### GooList Type Handling

The GooList type (used by ProcessDirtyTrees, ProcessSomeMUpstream, ReconcileMUpstream, McGetUpStreamByList, McGetDownStreamByList) has a `uid` column. This column must be CITEXT:

```sql
-- If GooList is defined as a composite type:
CREATE TYPE perseus_dbo.goolist AS (uid CITEXT);

-- If GooList uses a temp table pattern:
CREATE TEMPORARY TABLE tmp_goo_list (
    uid CITEXT NOT NULL
) ON COMMIT DROP;
```

---

## 5. Files to Read Before Starting

### Required reading (in order):

1. `docs/post-migration/CITEXT-PROCEDURES-UPDATE-GUIDE.md` -- per-procedure analysis
2. `docs/post-migration/CITEXT-FUNCTIONS-UPDATE-GUIDE.md` -- per-function analysis
3. `prompts/columns_citext_candidates.txt` -- the 172 ALTER statements (which columns changed)
4. `docs/post-migration/citext-dependency-analysis.md` -- FK/view/index dependency chain
5. `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md` -- coding standards (Articles I-XVII)

### Reference as needed:

- `docs/code-analysis/dependency/dependency-analysis-lote2-functions.md` -- function dependency graph
- `docs/code-analysis/dependency/dependency-analysis-consolidated.md` -- full 769-object dependency map
- `docs/db-design/pgsql/perseus-data-dictionary.md` -- current schema reference
- `docs/db-design/pgsql/TYPE-TRANSFORMATION-REFERENCE.md` -- type mapping reference
- `specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md` -- worktree and execution workflow

### Source files:

- `source/building/pgsql/refactored/20.create-procedure/` -- 15 procedure files to update
- `source/building/pgsql/refactored/19.create-function/` -- target for converted functions
- `source/original/sqlserver/11.create-routine/` -- original T-SQL source (functions + procedures)
- `source/original/pgsql-aws-sct-converted/19.create-function/` -- AWS SCT baseline for functions
- `tests/unit/` -- existing unit tests

---

## 6. Git Branch Strategy

```bash
# Create a new worktree from the main branch (or from the latest integrated branch)
git worktree add ~/.claude-worktrees/US{N}-citext-proc-func-update \
    -b us{N}-citext-proc-func-update main

# Work in the worktree
cd ~/.claude-worktrees/US{N}-citext-proc-func-update

# Commit frequently with conventional commits
git commit -m "feat(citext): update AddArc/RemoveArc parameter types to CITEXT"
git commit -m "feat(citext): update McGet* function signatures for CITEXT"
git commit -m "test(citext): add case-insensitive integration tests"

# Create PR when complete
gh pr create --base main --title "feat(US{N}): update proc/func types for CITEXT columns"
```

---

## 7. Quality Gates

All work must meet these gates before merging:

- [ ] **Score >= 7.0/10** on the 5-dimension quality framework (syntax, logic, performance, maintainability, security)
- [ ] **No dimension below 6.0/10**
- [ ] **All existing unit tests pass** (`tests/unit/test_*.sql`)
- [ ] **New tests created** for any function/procedure not currently covered
- [ ] **Zero P0/P1 issues** remaining
- [ ] **Performance within +/-20%** of pre-update baseline (EXPLAIN ANALYZE)
- [ ] **Case-insensitive behavior verified** with mixed-case test inputs
- [ ] **No implicit cast warnings** in PostgreSQL logs during test execution
- [ ] **FDW boundaries handled** with explicit casts (procedure 13, Hermes functions)
- [ ] **GooList type uid column** confirmed as CITEXT
- [ ] **All dependent views compile** after function updates
- [ ] **Full call chain tested** (AddArc --> McGet* --> Reconcile chain)

---

## 8. Common Pitfalls

1. **Do not change error-handling variables** -- `v_error_message TEXT`, `v_error_state TEXT`, `v_error_detail TEXT` should stay TEXT
2. **Do not change procedure name constants** -- `c_procedure_name CONSTANT VARCHAR` stores a string literal, not a CITEXT column value
3. **Foreign table columns stay unchanged** -- Hermes/Argus FDW columns are controlled by the remote server
4. **CITEXT requires the extension** -- verify `CREATE EXTENSION IF NOT EXISTS citext;` is in the deployment script
5. **CITEXT comparison is case-insensitive** -- `'ABC'::CITEXT = 'abc'::CITEXT` is TRUE. This is the desired behavior but may affect UNIQUE constraints or deduplication logic
6. **CITEXT in ORDER BY** -- sorting is case-insensitive. Verify this does not break expected ordering in result sets
7. **CITEXT and LIKE/ILIKE** -- CITEXT makes `LIKE` behave like `ILIKE`. If case-sensitive LIKE is needed (unlikely), cast to TEXT first
8. **Array types** -- if any function uses `VARCHAR[]` arrays for uid values, change to `CITEXT[]`
