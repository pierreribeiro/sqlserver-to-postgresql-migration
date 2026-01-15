<!--
  Sync Impact Report:

  Version Change: INITIAL → 1.0.0

  Modified Principles: N/A (initial creation)

  Added Sections:
  - All 7 core principles extracted from PostgreSQL Programming Constitution v1.0
  - Quality Standards section (from Article XV)
  - Migration Standards section (from Articles XIV, XVI, XVII)
  - Governance section with compliance requirements

  Templates Status:
  - ✅ plan-template.md: Constitution Check section already references constitution file
  - ✅ spec-template.md: No constitution-specific constraints requiring updates
  - ✅ tasks-template.md: Phase organization aligns with constitution principles

  Follow-up TODOs: None - all placeholders resolved

  Notes:
  - Constitution derived from POSTGRESQL-PROGRAMMING-CONSTITUTION.md v1.1 (2026-01-14)
  - Adapted to speckit format while preserving all binding requirements
  - All 17 articles from original constitution preserved in principles and sections
-->

# Perseus Database Migration Constitution

## Core Principles

### I. ANSI-SQL Primacy

**Prioritize standard ANSI SQL syntax over vendor-specific extensions.**

This principle ensures:
- Business logic is portable and readable across database platforms
- Migration from SQL Server to PostgreSQL follows industry standards
- Minimal dialect coupling reduces technical debt
- Code maintainability improves through standardization

**Rationale**: Vendor-specific extensions create lock-in and complicate future migrations. Standard SQL is self-documenting and widely understood.

### II. Strict Typing & Explicit Casting

**All data type conversions MUST be explicit using CAST or :: notation.**

Unlike SQL Server's implicit conversions, PostgreSQL enforces strict typing:
- ALL type conversions require explicit CAST(value AS type) or value::type syntax
- NO reliance on implicit type coercion
- Query plan stability through predictable type handling
- Runtime errors prevented through compile-time type checking

**Rationale**: Strict typing prevents subtle bugs, ensures query plan stability, and makes data transformations transparent and auditable.

### III. Set-Based Execution (NON-NEGOTIABLE)

**Eliminate Row-By-Agonizing-Row (RBAR) patterns. Favor set-based operations.**

Mandatory requirements:
- NO WHILE loops for data processing (use CTEs, window functions, or batch operations)
- NO cursors except for genuinely sequential operations (e.g., calling external APIs per row)
- PREFER Common Table Expressions (CTEs) over temporary tables
- LEVERAGE PostgreSQL query optimizer through set-based queries

**Rationale**: Set-based operations achieve 10-100× performance improvements over row-by-row processing. PostgreSQL optimizer excels with set operations.

### IV. Atomic Transaction Management

**Explicitly manage transaction boundaries and error handling.**

Requirements:
- Use BEGIN/COMMIT/ROLLBACK explicitly (not implicit transactions)
- Implement proper exception handling with specific error types
- Account for PostgreSQL function/procedure transaction behavior differences
- Use savepoints for partial rollback scenarios
- Keep transactions SHORT (< 10 minutes to avoid termination)

**Rationale**: PostgreSQL's transaction model differs from SQL Server. Explicit control prevents data corruption and enables proper error recovery.

### V. Idiomatic Naming & Scoping

**Use snake_case lowercase naming for ALL database objects. Avoid reserved words.**

Naming standards (from Article I):
- Tables: plural nouns (customers, order_items)
- Views: v_ prefix (v_active_customers)
- Functions: action verb prefix (get_customer_by_id, process_order_batch)
- Indexes: descriptive with suffix (_pkey, _idx, _fkey)
- Variables: snake_case with _ suffix for parameter disambiguation
- NO Hungarian notation (sp_, tbl_, fn_ prefixes)
- NO PascalCase or camelCase
- MAX 63 characters (PostgreSQL identifier limit)

**Rationale**: Native PostgreSQL conventions ensure seamless CLI integration, prevent quoting issues, and improve cross-team readability.

### VI. Structured Error Resilience

**Implement standardized EXCEPTION blocks with meaningful telemetry.**

Error handling requirements:
- Use specific exception types (unique_violation, foreign_key_violation) over generic WHEN OTHERS
- Include context in error messages (parameter values, operation state)
- Log errors with appropriate severity: DEBUG, LOG, INFO, NOTICE, WARNING, EXCEPTION
- MINIMIZE exception blocks in loops (each creates savepoint overhead)
- Use ON CONFLICT for upsert operations instead of exception handling
- NEVER swallow errors silently

**Rationale**: Proper error handling enables rapid troubleshooting, prevents data corruption, and provides audit trails for compliance.

### VII. Modular Logic Separation

**Maintain "Clean Schema" architecture with schema-qualified object references.**

Architecture requirements:
- Separate data storage schemas from procedural logic schemas
- ALL object references MUST be schema-qualified (schema_name.object_name)
- AVOID search_path dependencies (security vulnerability)
- Function/procedure signatures MUST use named parameters (not positional)
- Document all objects with COMMENT ON statements
- One responsibility per function/procedure

**Rationale**: Schema qualification prevents ambiguity, search_path vulnerabilities, and name collisions. Modular design improves testability and reusability.

## Quality Standards

**From PostgreSQL Programming Constitution Article XV**

### Code Review Requirements

All database code changes require:
1. Self-review against this Constitution
2. Technical Lead review
3. DBA review for production deployment
4. EXPLAIN ANALYZE results for new queries

### Quality Score Dimensions

Code quality assessed across five dimensions (minimum 7.0/10 overall, no dimension below 6.0):

| Dimension | Weight | Criteria |
|-----------|--------|----------|
| Syntax Correctness | 20% | Valid PostgreSQL 17 syntax, no errors |
| Logic Preservation | 30% | Business logic identical to original |
| Performance | 20% | Within 20% of SQL Server baseline |
| Maintainability | 15% | Readable, documented, follows Constitution |
| Security | 15% | No injection risks, proper permissions |

### Violation Handling

| Severity | Action Required | SLA |
|----------|-----------------|-----|
| P0 - Critical | Block deployment, immediate fix | Before any testing |
| P1 - High | Fix before deployment | Within sprint |
| P2 - Medium | Fix in next sprint | Next sprint |
| P3 - Low | Track for future | Backlog |

**Minimum passing score: 7.0/10 overall, no individual dimension below 6.0**

## Migration Standards

**From PostgreSQL Programming Constitution Articles XIV, XVI, XVII**

### SQL Server to PostgreSQL Conversion Rules

**Mandatory transformations:**

1. **Temporary Tables**: `CREATE TABLE #temp` → `CREATE TEMPORARY TABLE tmp_name ON COMMIT DROP`
2. **Identity Columns**: `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
3. **String Concatenation**: `+` operator → `||` operator or CONCAT()
4. **Top N Rows**: `SELECT TOP n` → `LIMIT n`
5. **NULL Comparison**: `= NULL` → `IS NULL`
6. **Transaction Control**: `BEGIN TRAN` → `BEGIN` (or use procedures)
7. **Conditional Logic**: `IIF(cond, t, f)` → `CASE WHEN cond THEN t ELSE f END`
8. **Date Functions**: `GETDATE()` → `CURRENT_TIMESTAMP`, `DATEADD()` → `+ INTERVAL`
9. **String Functions**: `LEN()` → `LENGTH()`, `ISNULL()` → `COALESCE()`
10. **Linked Servers**: OPENQUERY → Foreign Data Wrapper (postgres_fdw)

### Naming Convention Transitions

**PascalCase to snake_case conversion (Article XVI):**

```
SQL Server (PascalCase)         → PostgreSQL (snake_case)
────────────────────────────────────────────────────────
GetMaterialByRunProperties      → get_material_by_run_properties
ReconcileMUpstream              → reconcile_mupstream
sp_MoveNode                     → move_node (drop sp_ prefix)
fn_CalculateTotal               → calculate_total (drop fn_ prefix)
```

**Coordination required:**
- Document all name changes before deployment
- Update database job references
- Notify development team
- Update migration scripts
- Maintain mapping table in project documentation

### Pre-Conversion Checklist

Before converting any SQL Server object:

- [ ] Original T-SQL source code obtained
- [ ] AWS SCT conversion output reviewed
- [ ] Dependencies identified (callers and callees)
- [ ] Test data/scenarios documented
- [ ] Expected behavior baseline established

### Post-Conversion Validation

**MANDATORY after conversion:**

1. **Syntax validation**: Execute in PostgreSQL without errors
2. **Logic validation**: Compare output with SQL Server for same inputs
3. **Performance validation**: EXPLAIN ANALYZE, compare with baseline (within 20%)
4. **Edge case validation**: NULL handling, empty sets, boundary conditions

### Common AWS SCT Issues to Fix

**P0 Issues (Always check):**
- Temp table initialization: `SELECT INTO #temp` requires manual fix
- Transaction control: `BEGIN TRAN` requires conversion
- Identity insert: `SET IDENTITY_INSERT ON` needs alternative approach
- Null comparison: `= NULL` must become `IS NULL`

**P1 Issues (Performance):**
- Remove unnecessary NOLOCK hints
- Remove index hints (trust PostgreSQL planner)
- Eliminate excessive LOWER() that AWS SCT adds unnecessarily
- Add explicit NULL handling with COALESCE where missing

## Governance

**Constitution supersedes all other development practices and guidelines.**

### Amendment Procedure

1. Proposed changes require documentation with:
   - Rationale for change
   - Impact analysis on existing code
   - Migration plan for affected artifacts

2. Amendments require approval from:
   - Project Lead (Pierre Ribeiro)
   - Technical Lead
   - At least one DBA reviewer

3. Version increments follow semantic versioning:
   - **MAJOR**: Backward-incompatible principle removals or redefinitions
   - **MINOR**: New principle/section added or materially expanded guidance
   - **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements

### Compliance Requirements

**All pull requests and code reviews MUST verify:**
- [ ] All seven core principles followed
- [ ] Quality score dimensions meet minimum thresholds (7.0/10 overall)
- [ ] Migration standards applied for SQL Server conversions
- [ ] Schema-qualified object references used
- [ ] Proper error handling implemented
- [ ] Performance validated (within 20% of baseline)
- [ ] Documentation complete (COMMENT ON statements)

**Complexity must be justified:**
- Any violation of principles requires documented justification
- Simpler alternatives must be evaluated and rejection reason provided
- Technical debt tracked and scheduled for remediation

### Enforcement

- Constitution compliance gates all deployments to production
- Quality scores below 7.0/10 block deployment
- P0 violations prevent any testing or deployment
- Repeat violations trigger architectural review

### Related Documentation

- **Detailed Standards**: `/docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md` (Articles I-XVII)
- **Core Principles**: `/docs/Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md`
- **Project History**: `/docs/Project-History.md`
- **Quick Reference**: PostgreSQL Programming Constitution Appendix A

**Version**: 1.0.0 | **Ratified**: 2026-01-13 | **Last Amended**: 2026-01-14
