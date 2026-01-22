# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Perseus Database Migration Project** - Converting 15 SQL Server stored procedures to PostgreSQL 17+. This is a production-critical migration requiring zero defects and systematic validation at every step.

**Migration Strategy:**
1. AWS Schema Conversion Tool (SCT) provides baseline conversion (~70% complete)
2. Manual review and correction fixes critical issues (~30% effort)
3. Comprehensive validation before deployment (syntax, performance, data integrity)

**Current Status:** Sprint 3 complete (3/15 procedures migrated with 8.67/10 avg quality score)

## Project Structure

```
source/
├── original/
│   ├── sqlserver/              # Original T-SQL procedures (15 files)
│   └── pgsql-aws-sct-converted/  # AWS SCT baseline output
└── building/
    └── pgsql/
        └── refactored/         # Production-ready PostgreSQL procedures

docs/
├── POSTGRESQL-PROGRAMMING-CONSTITUTION.md  # Binding programming standards
├── Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md  # 7 core principles
├── PROJECT-SPECIFICATION.md    # Detailed project requirements
└── code-analysis/
    ├── procedures/             # Per-procedure analysis documents
    └── dependency-analysis-*.md  # Dependency mappings

scripts/
├── automation/                 # Python scripts for analysis generation
│   └── requirements.txt        # Python dependencies (sqlparse, click, pandas, rich, etc.)
└── validation/                 # Quality gate scripts
    └── check-setup.sh          # Environment validation

tests/
├── unit/                       # Per-procedure unit tests
├── integration/                # Cross-procedure integration tests
└── performance/                # Performance benchmarks vs SQL Server baseline

tracking/
├── progress-tracker.md         # Current sprint status (update daily during sprints)
├── activity-log-YYYY-MM.md     # Session-level activity logs
└── TRACKING-PROCESS.md         # Tracking methodology

specs/001-tsql-to-pgsql/        # Active feature specification artifacts
templates/                      # SQL procedure templates and guides
```

## Commands

### Environment Setup
```bash
# Validate development environment setup
./scripts/validation/check-setup.sh

# Install Python automation dependencies
pip install -r scripts/automation/requirements.txt
```

### Testing & Validation
```bash
# Run syntax validation on a procedure
./scripts/validation/syntax-check.sh <procedure_file.sql>

# Run unit tests for a specific procedure
psql -h localhost -d perseus_dev -f tests/unit/test_<procedure_name>.sql

# Run dependency check
psql -h localhost -d perseus_dev -f scripts/validation/dependency-check.sql

# Run data integrity validation
psql -h localhost -d perseus_dev -f scripts/validation/data-integrity-check.sql

# Run performance benchmark
psql -h localhost -d perseus_dev -f scripts/validation/performance-test.sql
```

### Analysis & Documentation
```bash
# Generate analysis document for a procedure
python scripts/automation/analyze-procedure.py \
  --original source/original/sqlserver/<ProcedureName>.sql \
  --converted source/original/pgsql-aws-sct-converted/<procedurename>.sql \
  --output docs/code-analysis/procedures/<procedurename>-analysis.md

# Generate side-by-side comparison
python scripts/automation/compare-versions.py \
  --original source/original/sqlserver/<ProcedureName>.sql \
  --aws-sct source/original/pgsql-aws-sct-converted/<procedurename>.sql \
  --corrected source/building/pgsql/refactored/<procedurename>.sql \
  --output docs/code-analysis/procedures/<procedurename>-diff.html

# Auto-generate test template
python scripts/automation/generate-tests.py \
  --procedure source/building/pgsql/refactored/<procedurename>.sql \
  --output tests/unit/test_<procedurename>.sql
```

### Deployment (When Ready)
```bash
# Deploy to DEV environment
./scripts/deployment/deploy-procedure.sh <procedure_name>.sql dev

# Run smoke tests
./scripts/deployment/smoke-test.sh <procedure_name> dev

# Deploy to QA (requires DEV validation)
./scripts/deployment/deploy-procedure.sh <procedure_name>.sql qa

# Deploy to PROD (requires QA approval + change control)
./scripts/deployment/deploy-procedure.sh <procedure_name>.sql prod
```

## Critical Architecture Principles

**MANDATORY: ALL code MUST comply with these 7 principles** (from `.specify/memory/constitution.md`):

1. **ANSI-SQL Primacy** - Prioritize standard SQL over vendor extensions. Business logic must be portable.

2. **Strict Typing & Explicit Casting** - PostgreSQL requires explicit type conversions. NEVER rely on implicit casting. Use `CAST(x AS type)` or `x::type` notation.

3. **Set-Based Execution (NON-NEGOTIABLE)** - Eliminate WHILE loops and cursors. Use CTEs, window functions, and bulk operations. Set-based operations are 10-100× faster.

4. **Atomic Transaction Management** - Explicitly manage BEGIN/COMMIT/ROLLBACK. PostgreSQL's transaction model differs from SQL Server. Keep transactions SHORT (< 10 min to avoid termination).

5. **Idiomatic Naming & Scoping** - Use `snake_case` lowercase exclusively. NO PascalCase. NO Hungarian notation (sp_, fn_ prefixes). Max 63 chars. Schema-qualify ALL object references (`schema.object_name`).

6. **Structured Error Resilience** - Use specific exception types (NOT just `WHEN OTHERS`). Include context in errors. NEVER swallow exceptions silently.

7. **Modular Logic Separation** - Separate data schemas from logic schemas. Schema-qualify all references to prevent search_path vulnerabilities.

## Quality Standards & Gates

**Minimum Quality Score: 7.0/10 overall, NO dimension below 6.0/10**

Quality dimensions (from constitution):
- **Syntax Correctness** (20%): Valid PostgreSQL 17 syntax, zero errors
- **Logic Preservation** (30%): Business logic identical to SQL Server original
- **Performance** (20%): Within ±20% of SQL Server baseline
- **Maintainability** (15%): Readable, documented, follows constitution
- **Security** (15%): No SQL injection risks, proper permissions

**Violation Severity Levels:**
- **P0 (Critical)**: Blocks ALL testing and deployment. Fix immediately.
- **P1 (High)**: Must fix before deployment. Can proceed with testing.
- **P2 (Medium)**: Fix before QA deployment. OK for DEV testing.
- **P3 (Low)**: Track for future improvement. Non-blocking.

**Deployment Quality Gates:**
- DEV: Can deploy with minor issues, used for initial testing
- QA: ZERO P0/P1 issues, all tests passing
- PROD: QA sign-off + zero tolerance + monitoring + rollback plan + runbook

## Common T-SQL → PostgreSQL Transformations

**ALWAYS apply these conversions** (from constitution Article XIV):

| SQL Server (T-SQL) | PostgreSQL (PL/pgSQL) | Notes |
|--------------------|----------------------|-------|
| `CREATE TABLE #temp` | `CREATE TEMPORARY TABLE tmp_name ON COMMIT DROP` | Temp table syntax |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | NOT SERIAL |
| `+` (concat strings) | `\|\|` or `CONCAT()` | String concatenation |
| `SELECT TOP n` | `LIMIT n` | Row limiting |
| `= NULL` | `IS NULL` | Null comparison |
| `BEGIN TRAN` | `BEGIN` | Transaction control |
| `IIF(cond, t, f)` | `CASE WHEN cond THEN t ELSE f END` | Conditional |
| `GETDATE()` | `CURRENT_TIMESTAMP` | Current datetime |
| `DATEADD()` | `+ INTERVAL '1 day'` | Date arithmetic |
| `LEN()` | `LENGTH()` | String length |
| `ISNULL(x, y)` | `COALESCE(x, y)` | Null coalescing |
| `RAISERROR` | `RAISE EXCEPTION` | Error raising |

## Procedure Workflow

When migrating a stored procedure, follow this exact sequence:

### Phase 1: Analysis
1. Read original T-SQL from `source/original/sqlserver/`
2. Read AWS SCT output from `source/original/pgsql-aws-sct-converted/`
3. Generate analysis document using `scripts/automation/analyze-procedure.py`
4. Review analysis, categorize issues (P0/P1/P2/P3)
5. Calculate quality score (must be ≥7.0/10 after corrections)

### Phase 2: Correction
1. Start with AWS SCT output as baseline
2. Apply fixes for ALL P0 issues (critical blockers)
3. Apply fixes for ALL P1 issues (high priority)
4. Address P2 issues or document justification
5. Add comprehensive error handling (`EXCEPTION` blocks)
6. Add header documentation (see template below)
7. Ensure schema-qualified references throughout
8. Save to `source/building/pgsql/refactored/`

### Phase 3: Validation
1. **Syntax**: Run `./scripts/validation/syntax-check.sh` (must pass)
2. **Dependencies**: Run dependency-check.sql (must pass)
3. **Unit Tests**: Create/update tests in `tests/unit/` (must pass)
4. **Performance**: Run performance benchmark (within ±20% of baseline)
5. **Data Integrity**: Run data-integrity-check.sql (must pass)
6. **Peer Review**: Get code review approval

### Phase 4: Deployment
1. Deploy to DEV environment
2. Run smoke tests in DEV
3. Deploy to QA (requires passing DEV)
4. Integration testing in QA
5. Deploy to PROD (requires QA sign-off + change control)

## Procedure Template Structure

**ALWAYS use this structure for corrected procedures:**

```sql
-- =============================================================================
-- Procedure: schema.procedure_name
-- Description: [Brief description]
--
-- Original: SQL Server T-SQL (PascalCase name from SQL Server)
-- Converted: AWS SCT + Manual Review
-- Quality Score: X.X/10
--
-- Author: Pierre Ribeiro (DBA/DBRE)
-- Created: YYYY-MM-DD
-- Modified: YYYY-MM-DD
--
-- Dependencies:
--   Tables: [schema.table1, schema.table2]
--   Functions: [schema.function1]
--   Procedures: [schema.procedure1]
--
-- Parameters:
--   p_param1 TYPE - Description
--   p_param2 TYPE - Description
--
-- Returns: [Description]
--
-- Performance: [vs SQL Server baseline]
--
-- Example Usage:
--   SELECT * FROM schema.procedure_name(param1_val, param2_val);
--
-- Change Log:
--   YYYY-MM-DD - Initial PostgreSQL version (AWS SCT baseline)
--   YYYY-MM-DD - P0/P1 fixes applied
--   YYYY-MM-DD - Performance optimization
-- =============================================================================

CREATE OR REPLACE FUNCTION schema.procedure_name(
    p_param1_ TYPE,  -- Note: underscore suffix to avoid column name conflicts
    p_param2_ TYPE
)
RETURNS TABLE(...) -- or VOID for procedures
LANGUAGE plpgsql
SECURITY DEFINER  -- or INVOKER, as appropriate
AS $$
DECLARE
    -- Variable declarations with meaningful names
    v_local_var TYPE;
BEGIN
    -- Explicit transaction management if needed
    -- BEGIN; (only in procedures, not functions)

    -- Implementation with inline comments for complex logic
    -- ALWAYS schema-qualify object references
    SELECT col INTO v_local_var
    FROM schema_name.table_name
    WHERE condition;

    -- Set-based operations (NO loops/cursors unless justified)
    -- Use CTEs for complex queries

    RETURN QUERY
    SELECT ...;

    -- COMMIT; (if using transactions in procedures)

EXCEPTION
    WHEN unique_violation THEN
        -- Specific exception handling
        RAISE EXCEPTION 'Duplicate key: %', SQLERRM
            USING ERRCODE = 'unique_violation';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Foreign key violation: %', SQLERRM
            USING ERRCODE = 'foreign_key_violation';
    WHEN OTHERS THEN
        -- Generic handler only as last resort
        RAISE EXCEPTION 'Unexpected error in procedure_name: %', SQLERRM
            USING ERRCODE = '50000';
        -- ROLLBACK; (if in transaction)
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION schema.procedure_name(...) TO appropriate_role;

-- Add system catalog comment
COMMENT ON FUNCTION schema.procedure_name(...) IS
'Brief description for system catalog (shows in \df+ output)';
```

## Tracking & Reporting

**Update tracking documents during active work:**

1. **Daily Progress** (during sprints): Update `tracking/progress-tracker.md`
   - Mark completed tasks
   - Update time spent
   - Note blockers
   - Update metrics dashboard

2. **Activity Logging**: Log each session in `tracking/activity-log-YYYY-MM.md`
   - Session date/time
   - Tasks worked on
   - Decisions made
   - Issues encountered

3. **Sprint Archives**: At sprint end, archive to `tracking/progress-tracker-archive-sprints-*.md`

## Naming Conventions

**PascalCase → snake_case conversion (MANDATORY):**

```
SQL Server (Original)           PostgreSQL (Converted)
─────────────────────────────────────────────────────
GetMaterialByRunProperties  →   get_material_by_run_properties
ReconcileMUpstream          →   reconcile_mupstream
sp_MoveNode                 →   move_node (drop sp_ prefix)
usp_UpdateContainerType     →   update_container_type (drop usp_ prefix)
```

**Object naming rules:**
- Tables: `plural_nouns` (customers, order_items)
- Views: `v_prefix` (v_active_customers)
- Functions/Procedures: `verb_noun` (get_customer, process_order)
- Temp tables: `tmp_prefix` (tmp_processing_batch)
- Indexes: `descriptive_suffix` (customers_email_idx)
- Variables: `v_prefix` or `_suffix` for parameters (v_count, customer_id_)

## Key Documentation References

**Read these FIRST before making code changes:**

1. **Constitution** (`.specify/memory/constitution.md`) - All 7 binding principles
2. **Detailed Standards** (`docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`) - Articles I-XVII
3. **Project Spec** (`docs/PROJECT-SPECIFICATION.md`) - Requirements and constraints
4. **Core Principles** (`docs/Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md`) - Quick reference

**Procedure-specific analysis:**
- Check `docs/code-analysis/procedures/` for existing analysis documents
- Review dependency mappings in `docs/code-analysis/dependency-analysis-*.md`

## Performance Expectations

**Established baseline from Sprint 3:**
- Analysis time: 1-2 hours per procedure (was 4-6 hours before automation)
- Correction time: 2-3 hours per procedure (with pattern reuse)
- Average quality score: 8.67/10 (Sprint 3 achievement)
- Performance vs SQL Server: +63% to +97% improvement (far exceeds ±20% target)

**Velocity multiplier:** Pattern reuse provides 5-6× faster delivery vs estimates.

## Testing Standards

**MANDATORY test coverage for each procedure:**

1. **Happy Path**: Normal execution with valid inputs
2. **Null Handling**: NULL parameter tests
3. **Edge Cases**: Empty strings, zero values, boundary conditions
4. **Error Scenarios**: Foreign key violations, unique constraints, transaction rollbacks
5. **Performance Baseline**: Execution time benchmark vs SQL Server

**Test file location:** `tests/unit/test_<procedure_name>.sql`

## Git Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Examples
git commit -m "feat: add corrected version of reconcile_mupstream procedure"
git commit -m "fix: correct transaction handling in process_dirty_trees"
git commit -m "docs: update Sprint 3 completion status in README"
git commit -m "test: add edge case tests for add_arc procedure"
git commit -m "perf: optimize CTE in get_material_by_run_properties"
```

## Common Pitfalls to Avoid

1. **Implicit Type Casting**: PostgreSQL does NOT do implicit conversions. ALWAYS cast explicitly.
2. **Transaction Scope**: Functions run in outer transaction. Use PROCEDURES for autonomous transactions.
3. **Temp Table Syntax**: `#temp` doesn't work. Use `CREATE TEMPORARY TABLE tmp_name`.
4. **Search Path Reliance**: NEVER depend on search_path. Schema-qualify everything.
5. **WHILE Loops**: Almost always wrong. Use set-based operations instead.
6. **Generic Exception Handling**: Use specific exception types, not just `WHEN OTHERS`.
7. **AWS SCT Output Blind Trust**: SCT output is ~70% complete. ALWAYS requires manual review.
8. **Missing Transaction Control**: PostgreSQL procedures need explicit BEGIN/COMMIT.
9. **Case-Sensitive Comparisons**: Use `LOWER()` or `ILIKE` for case-insensitive matching.
10. **Unqualified Object Names**: Always use `schema_name.object_name` notation.

## Sprint Progress Reference

**Completed Procedures (Sprint 3):**
- ✅ AddArc (Quality: 8.5/10, Perf: +90%)
- ✅ RemoveArc (Quality: 9.0/10, Perf: +50-100%)
- ✅ ProcessDirtyTrees (Quality: 8.5/10, 4 P0 fixes)

**Remaining:** 12 procedures across P1, P2, P3 priorities

**Next Priority:** Complete Sprint 2 dependencies (ProcessSomeMUpstream, ReconcileMUpstream, usp_UpdateMUpstream, usp_UpdateMDownstream)

---

**Project Lead:** Pierre Ribeiro (Senior DBA/DBRE)
**Last Updated:** 2026-01-22
**Project Status:** Sprint 3 Complete - 20% procedures migrated
