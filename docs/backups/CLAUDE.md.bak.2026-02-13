# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Perseus Database Migration** - SQL Server → PostgreSQL 17+. Production-critical migration of **769 database objects** with zero-defect requirement and systematic validation.

**Migration Strategy:**
1. AWS Schema Conversion Tool (SCT) provides baseline (~70% complete)
2. Manual review and correction fixes critical issues (~30% effort)
3. Comprehensive validation (syntax, performance, data integrity) before deployment

**Current Status:** 15/15 stored procedures complete ✅ | Ready for views/functions/tables phase

---

## ⚠️ MANDATORY: User Story Workflow (READ FIRST)

**CRITICAL**: Before starting ANY User Story work, you MUST read and follow:

📖 **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`**

This guide defines **REQUIRED** practices for:
1. **Worktree Strategy**: Each User Story works in isolated git worktree (`~/.claude-worktrees/`)
2. **Parallel Execution**: Maximize throughput with concurrent task execution
3. **Database Agents**: Mandatory use (database-expert, sql-pro, database-optimization)
4. **Ralph Loop Plugin**: Required for batch conversions (10+ objects)
5. **Branch Strategy**: `001-tsql-to-pgsql` is parent for all User Story branches

**Quick Checklist** (per User Story):
- [ ] Create worktree: `git worktree add ~/.claude-worktrees/US{X}-{name} -b us{X}-{name} 001-tsql-to-pgsql`
- [ ] Activate database-expert agent (PRIMARY for all SQL work)
- [ ] Enable Ralph Loop for batch tasks (analysis, refactoring, testing)
- [ ] Run `[P]` marked tasks in parallel (multiple sessions/agents)
- [ ] Update `tracking/progress-tracker.md` after each task group

**Non-Compliance = Rejected Work**: Worktree isolation and database agent usage are NON-NEGOTIABLE.

---

## Project Scope - 769 Database Objects

| Object Type | Count | Status | Notes |
|-------------|-------|--------|-------|
| **Stored Procedures** | 15 | ✅ COMPLETE | Average quality: 8.67/10, Performance: +63-97% |
| **Functions** | 25 | Pending | 15 table-valued, 10 scalar |
| **Views** | 22 | Pending | 1 materialized, 21 recursive CTEs |
| **Tables** | 91 | Pending | Core schema objects |
| **Indexes** | 352 | Pending | Primary keys, foreign keys, query optimization |
| **Constraints** | 271 | Pending | Primary keys, foreign keys, unique, check |
| **UDT (GooList)** | 1 | Pending | Convert to TEMPORARY TABLE pattern |
| **FDW Connections** | 3 | Pending | hermes, sqlapps, deimeter (17 foreign tables) |
| **SQL Agent Jobs** | 7 | Pending | Migrate to pg_cron/pgAgent |

**P0 Critical Path:** `translated` view (materialized), `mcgetupstream`/`mcgetdownstream`/`mcgetupstreambylist`/`mcgetdownstreambylist` functions, `goo`/`material_transition`/`transition_material` tables

## Directory Structure

```
source/
├── original/
│   ├── sqlserver/              # 822 files - Original T-SQL (0-21 dependency-ordered)
│   └── pgsql-aws-sct-converted/  # 1,385 files - AWS SCT baseline (~70% complete)
└── building/pgsql/refactored/  # Production-ready (0-21 dependency-ordered)
    ├── 0. drop-trigger/ ... 13. create-domain/
    ├── 14. create-table/       # Tables pending
    ├── 15. create-view/        # Views pending (22 views)
    ├── 16. create-index/       # Indexes pending (352 indexes)
    ├── 17-18. constraints/     # Constraints pending (271)
    ├── 19. create-function/    # Functions pending (25 functions)
    ├── 20. create-procedure/   # ✅ 15 procedures COMPLETE
    └── 21. create-trigger/     # Triggers pending

docs/code-analysis/             # dependency-analysis-*.md (4 lote + consolidated)
scripts/                        # automation/ (🚧), validation/ (✅), deployment/ (🚧)
tests/unit/                     # ✅ 15 test_*.sql files for procedures
tracking/                       # progress-tracker.md, activity-log-*.md
templates/                      # procedure, function, view, test templates
specs/001-tsql-to-pgsql/       # spec.md, data-model.md, plan.md, tasks.md (317 tasks)
```

## Quick Commands

**Status:** ✅ Available | 🚧 Planned (documented in scripts/*/README.md)

```bash
# Environment (✅ Available)
./scripts/validation/check-setup.sh
pip install -r scripts/automation/requirements.txt

# Analysis (🚧 Planned - see scripts/automation/README.md)
# python scripts/automation/analyze-object.py --type [procedure|function|view|table]

# Validation (🚧 Planned - use psql directly for now)
psql -d perseus_dev -f <object>.sql  # Syntax validation
psql -d perseus_dev -f scripts/validation/dependency-check.sql

# Deployment (🚧 Planned - manual psql deployment for now)
psql -d perseus_dev -f source/building/pgsql/refactored/<object>.sql

# Testing (✅ 15 procedure tests exist in tests/unit/)
psql -d perseus_dev -f tests/unit/test_<object>.sql
```

## 7 Core Principles (MANDATORY)

**ALL code MUST comply** (from `.specify/memory/constitution.md`):

1. **ANSI-SQL Primacy** - Standard SQL over vendor extensions, portable logic
2. **Strict Typing & Explicit Casting** - Use `CAST(x AS type)` or `x::type`, never implicit
3. **Set-Based Execution** (NON-NEGOTIABLE) - No WHILE loops/cursors, use CTEs/window functions (10-100× faster)
4. **Atomic Transaction Management** - Explicit BEGIN/COMMIT/ROLLBACK, transactions <10 min
5. **Idiomatic Naming & Scoping** - `snake_case` only, schema-qualify ALL refs, 63 char max
6. **Structured Error Resilience** - Specific exception types (not `WHEN OTHERS` only), include context
7. **Modular Logic Separation** - Schema-qualify to prevent search_path vulnerabilities

**Full details:** `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md` (Articles I-XVII)

## T-SQL → PostgreSQL Transformations

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `CREATE TABLE #temp` | `CREATE TEMPORARY TABLE tmp_name ON COMMIT DROP` | Temp table |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | NOT SERIAL |
| `+` (concat) | `\|\|` or `CONCAT()` | String concat |
| `SELECT TOP n` | `LIMIT n` | Row limit |
| `= NULL` | `IS NULL` | Null comparison |
| `BEGIN TRAN` | `BEGIN` | Transaction |
| `IIF(cond, t, f)` | `CASE WHEN cond THEN t ELSE f END` | Conditional |
| `GETDATE()` | `CURRENT_TIMESTAMP` | Current time |
| `DATEADD()` | `+ INTERVAL '1 day'` | Date arithmetic |
| `LEN()` | `LENGTH()` | String length |
| `ISNULL(x, y)` | `COALESCE(x, y)` | Null coalesce |
| `RAISERROR` | `RAISE EXCEPTION` | Error raising |

## Quality Gates & Standards

**Quality Score Framework (5 dimensions):**
- Syntax Correctness (20%): Valid PostgreSQL 17 syntax
- Logic Preservation (30%): Business logic identical to SQL Server
- Performance (20%): Within ±20% of SQL Server baseline
- Maintainability (15%): Readable, documented, follows constitution
- Security (15%): No SQL injection, proper permissions

**Minimum Scores:** 7.0/10 overall, NO dimension below 6.0/10

**Violation Severity:**
- **P0 (Critical)**: Blocks ALL testing/deployment - fix immediately
- **P1 (High)**: Must fix before PROD deployment
- **P2 (Medium)**: Fix before STAGING deployment
- **P3 (Low)**: Track for future improvement

**Deployment Gates:**
- DEV: Can deploy with minor issues
- STAGING: ZERO P0/P1 issues, all tests passing, ≥7.0/10 score
- PROD: STAGING sign-off + ≥8.0/10 target score + rollback plan

## Object-Specific Migration Workflows

### A. Procedures & Functions (4 phases)
1. **Analysis**: Read original T-SQL + AWS SCT, identify P0-P3 issues
2. **Correction**: Fix issues, add error handling, schema-qualify references
3. **Validation**: Syntax → dependency → unit tests → performance benchmark
4. **Deployment**: DEV → STAGING → PROD (smoke tests at each stage)

### B. Views
- **Standard views**: Test result set match (100%)
- **Indexed views**: Convert to **MATERIALIZED VIEW** with trigger refresh (`REFRESH MATERIALIZED VIEW CONCURRENTLY` + pg_cron every 10 min)
- **Recursive CTEs**: Validate recursion depth limits

### C. Tables, Indexes, Constraints
- **Tables**: `GENERATED ALWAYS AS IDENTITY`, data type mappings
- **Indexes**: Verify query plans use indexes, performance within ±20%
- **Constraints**: Validate cascade behavior, test constraint violations

### D. UDTs/TVPs
- **GooList TVP**: Convert to TEMPORARY TABLE pattern:
  ```sql
  CREATE TEMPORARY TABLE tmp_goo_list (
      goo_id INTEGER PRIMARY KEY
  ) ON COMMIT DROP;
  ```

### E. Foreign Data Wrappers (FDW)
- **Linked servers → postgres_fdw**: hermes, sqlapps, deimeter (17 foreign tables)
- Validate latency <2× baseline, optimize `fetch_size` (500-10k)

### F. SQL Agent Jobs → pg_cron/pgAgent
- Convert 7 jobs, validate schedule execution, logging, error handling

## Claude Code Skills & Directives

**HIGHLY RECOMMENDED (use proactively):**

1. **`database-expert`** - ALL SQL analysis, schema design, query optimization
   - When: Analyzing dependencies, designing migrations, troubleshooting

2. **`systematic-debugging`** - P0/P1 bugs or test failures
   - When: Syntax errors, logic issues, performance regressions

3. **`test-driven-development`** - BEFORE implementing functions/procedures
   - When: Starting new object conversion

4. **`code-reviewer`** - Self-review before committing/deploying
   - When: Completed object conversion

5. **`senior-backend`** - Architecture decisions (transactions, error patterns)
   - When: Designing complex functions

**MODERATELY USEFUL:**
- `senior-architect` - Cross-object dependency design
- `git-commit-helper` - Commit message generation

**Ralph Loop Plugin - USAGE CRITERIA:**

```bash
# Use /ralph-loop for:
✅ Batch conversions (10 similar views, 15 scalar functions)
✅ Iterative test-fix-retest cycles
✅ Multi-phase workflows with checkpoint validation
✅ Pattern-based migrations (same transformation × N objects)

# DO NOT use for:
❌ One-off object conversions (manual faster)
❌ Exploratory analysis (use Task tool with Explore agent)
❌ Complex objects requiring deep investigation

# Example - Perseus Project:
/ralph-loop
Task: Convert 22 views from lote3 (per dependency-analysis-lote3-views.md)
Order: P3 (simple) → P0 (translated materialized view last)
Iterate: analyze AWS SCT → apply constitution → schema-qualify → validate syntax
Checkpoint: After every 5 views, commit with quality scores
Gate: Before P0 translated view, validate ALL 21 view dependencies
Exit: All 22 views pass validation + performance benchmarks within ±20%
```

## Available MCP Tools

**GitHub Integration:**
- `issue_read` / `issue_write` - Track P0-P3 issues
- `pull_request_read` - Review migration PRs
- `search_code` - Find patterns across original/converted code

**Semantic Coding (Serena):**
- `find_symbol` - Navigate by function/procedure names
- `replace_symbol_body` - Refactor entire functions

**Codebase Context:**
- `index_codebase` / `search_code` - Semantic search

Use `ToolSearch` to discover full MCP catalog.

## Database Agents (Use PROACTIVELY)

**1. sql-pro** ⭐⭐⭐⭐⭐ - ALL SQL refactoring (analysis T034-T038, refactoring T040-T073, validation T047-T091)
**2. database-optimization** ⭐⭐⭐⭐ - Performance ±20% (T052, T118, T179-T183, T220-T222) + EXPLAIN ANALYZE
**3. shell-scripting-pro** ⭐⭐⭐⭐ - Bash scripts (T013-T021, T030) with `set -euo pipefail`
**4. database-admin** ⭐⭐⭐ - Infrastructure only (T006, T027, T254-T262, T291-T293)

## Naming Conventions

**PascalCase → snake_case (MANDATORY):**
```
SQL Server                  PostgreSQL
────────────────────────────────────────────────────
GetMaterialByRunProperties → get_material_by_run_properties
ReconcileMUpstream         → reconcile_mupstream
sp_MoveNode                → move_node (drop sp_ prefix)
usp_UpdateContainerType    → update_container_type (drop usp_)
```

**Object naming:**
- Tables: `plural_nouns` (customers, order_items)
- Views: `v_prefix` (v_active_customers) or descriptive (no prefix for materialized)
- Functions/Procedures: `verb_noun` (get_customer, process_order)
- Temp tables: `tmp_prefix` (tmp_processing_batch)
- Variables: `v_prefix` or `_suffix` for params (v_count, customer_id_)

## Common Pitfalls

1. Implicit casting → CAST() or :: | 2. #temp → CREATE TEMPORARY TABLE | 3. Search path → schema.object
4. WHILE loops → CTEs/window functions | 5. WHEN OTHERS only → Specific exceptions | 6. AWS SCT blind trust
7. Missing BEGIN/COMMIT | 8. Unqualified names | 9. Case-sensitive → LOWER()/ILIKE

## Documentation References

**Read FIRST before changes:**
- `.specify/memory/constitution.md` - 7 binding core principles
- `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md` - Articles I-XVII
- `docs/PROJECT-SPECIFICATION.md` - Requirements and constraints
- `docs/code-analysis/dependency-analysis-consolidated.md` - P0 critical path + all 769 objects
- `specs/001-tsql-to-pgsql/` - spec.md, data-model.md, plan.md, tasks.md
- `templates/` - Object templates (procedure, function, view, test)

## Tracking & Reporting

**Daily (during sprints):** `tracking/progress-tracker.md` - Tasks, metrics, blockers
**Per session:** `tracking/activity-log-YYYY-MM.md` - Date/time, tasks, decisions, issues
**Sprint end:** Archive to `tracking/progress-tracker-archive-sprints-*.md`

**Git commits** (Conventional Commits):
```bash
git commit -m "feat: add corrected view v_material_lineage"
git commit -m "fix: correct FK constraint in transition_material table"
git commit -m "docs: update dependency analysis for lote3 views"
git commit -m "test: add edge case tests for mcgetupstream function"
git commit -m "perf: optimize index on goo.parent_goo_id"
```

## Performance Baseline & Metrics

**Sprint 3 achievements (procedures):**
- Analysis: 1-2h per object (down from 4-6h with automation)
- Correction: 2-3h per object (with pattern reuse)
- Quality: 8.67/10 average (exceeds 7.0/10 minimum)
- Performance: +63% to +97% improvement vs SQL Server
- Velocity: 5-6× faster delivery with pattern reuse

**Apply these patterns to views, functions, tables for similar gains.**

---
**Project Lead:** Pierre Ribeiro (Senior DBA/DBRE) | **Last Updated:** 2026-01-22
**Status:** Procedures complete (15/15) | Ready for views/functions/tables phase | **Version:** 2.0 (expanded scope to 769 objects)
