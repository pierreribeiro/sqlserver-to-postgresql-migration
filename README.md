# SQL Server → PostgreSQL Migration Project
## Perseus Database Complete Migration

[![Project Status](https://img.shields.io/badge/status-procedures--complete-green)](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17+-blue)](https://www.postgresql.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2014-red)](https://www.microsoft.com/sql-server)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Objects](https://img.shields.io/badge/objects-769-orange)](docs/code-analysis/dependency-analysis-consolidated.md)
[![Procedures Complete](https://img.shields.io/badge/procedures-15%2F15-success)](source/building/pgsql/refactored/20.%20create-procedure/)

> **Mission:** Systematically migrate and validate ALL 769 Perseus database objects from SQL Server to PostgreSQL 17+ with zero production incidents and zero data loss.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Current Status](#-current-status)
- [Repository Structure](#-repository-structure)
- [Quick Start](#-quick-start)
- [Migration Scope](#-migration-scope)
- [Workflow](#-workflow)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [Contact](#-contact)

---

## 🎯 Project Overview

### Background

This project manages the **complete database migration** of **769 database objects** from SQL Server (T-SQL) to PostgreSQL 17+ (PL/pgSQL) for the Perseus system. The migration leverages AWS Schema Conversion Tool (SCT) as a baseline (~70% complete), with mandatory manual review and correction to ensure production quality.

**Migrated Objects:**
- ✅ **15 Stored Procedures** (COMPLETE - Sprint 3)
- 🔄 **25 Functions** (15 table-valued, 10 scalar)
- 🔄 **22 Views** (1 materialized, 21 recursive CTEs)
- 🔄 **91 Tables** (core schema objects)
- 🔄 **352 Indexes** (primary keys, foreign keys, query optimization)
- 🔄 **271 Constraints** (PK, FK, unique, check)
- 🔄 **1 UDT** (GooList → TEMPORARY TABLE pattern)
- 🔄 **3 FDW Connections** (hermes, sqlapps, deimeter - 17 foreign tables)
- 🔄 **7 SQL Agent Jobs** (migrate to pg_cron/pgAgent)

### Objectives

- ✅ Migrate ALL 769 database objects to PostgreSQL 17+
- ✅ Maintain or improve performance (within ±20% of SQL Server baseline)
- ✅ Zero production bugs (P0) in first 30 days post-migration
- ✅ Zero data loss (100% integrity validation)
- ✅ Complete documentation and operational runbooks
- ✅ Team trained on new architecture

### Three-Phase Strategy

1. **AWS SCT Conversion** - Automated baseline (~70% complete)
2. **Manual Review & Correction** - Critical fixes, optimizations, constitution compliance (~30%)
3. **Validation & Deployment** - Syntax → dependencies → unit tests → performance → DEV → STAGING → PROD

**Quality First:** Every object follows 4-phase workflow (Analysis → Correction → Validation → Deployment) with defined quality gates.

---

## 📊 Current Status

### Overall Progress - **Phase 1 Complete** 🎉

| Object Type | Total | Complete | Pending | Status |
|-------------|-------|----------|---------|--------|
| **Stored Procedures** | 15 | 15 ✅ | 0 | **COMPLETE** |
| **Functions** | 25 | 0 | 25 | Ready to start |
| **Views** | 22 | 0 | 22 | Ready to start |
| **Tables** | 91 | 0 | 91 | Ready to start |
| **Indexes** | 352 | 0 | 352 | Ready to start |
| **Constraints** | 271 | 0 | 271 | Ready to start |
| **UDT (GooList)** | 1 | 0 | 1 | Ready to start |
| **FDW Connections** | 3 | 0 | 3 | Ready to start |
| **SQL Agent Jobs** | 7 | 0 | 7 | Ready to start |
| **TOTAL** | **769** | **15** | **754** | **2% Complete** |

**Last Updated:** 2026-01-22

### Stored Procedures Achievement (Sprint 3)

**Completed:** 15/15 procedures (100%) ✅
- **Average Quality Score:** 8.67/10 (exceeds 7.0/10 minimum)
- **Performance Improvement:** +63% to +97% vs SQL Server baseline
- **Time Efficiency:** 5-6× faster delivery with pattern reuse
- **Analysis Time:** 1-2h per object (down from 4-6h with automation)
- **Correction Time:** 2-3h per object (with pattern reuse)

**Representative Procedures:**
- ✅ AddArc (Quality: 8.5/10, Perf: +90%)
- ✅ RemoveArc (Quality: 9.0/10, Perf: +50-100%)
- ✅ ProcessDirtyTrees (Quality: 8.5/10, 4 P0 fixes)
- ✅ ReconcileMUpstream (Quality: 8.2/10)
- ✅ GetMaterialByRunProperties, LinkUnlinkedMaterials, MoveContainer, and 8 others

**All 15 procedures** are production-ready in [source/building/pgsql/refactored/20. create-procedure/](source/building/pgsql/refactored/20.%20create-procedure/)

### Critical Path (P0 Objects - 9 total)

**MUST complete before other migrations:**
1. **Materialized View:** `translated` (indexed view conversion)
2. **Functions (4):** `mcgetupstream`, `mcgetdownstream`, `mcgetupstreambylist`, `mcgetdownstreambylist`
3. **Tables (3):** `goo`, `material_transition`, `transition_material`

---

## 📁 Repository Structure

```
sqlserver-to-postgresql-migration/
├── README.md                    # This file
├── CLAUDE.md                    # AI assistant guidance (v2.0)
├── source/
│   ├── original/
│   │   ├── sqlserver/           # 822 files - Original T-SQL (0-21 dependency-ordered)
│   │   └── pgsql-aws-sct-converted/  # 1,385 files - AWS SCT baseline (~70% complete)
│   └── building/
│       └── pgsql/
│           └── refactored/      # Production-ready PostgreSQL (0-21 dependency-ordered)
│               ├── 14. create-table/     # Tables pending
│               ├── 15. create-view/      # Views pending (22)
│               ├── 16. create-index/     # Indexes pending (352)
│               ├── 17-18. constraints/   # Constraints pending (271)
│               ├── 19. create-function/  # Functions pending (25)
│               ├── 20. create-procedure/ # ✅ 15 procedures COMPLETE
│               └── 21. create-trigger/   # Triggers pending
├── docs/
│   ├── POSTGRESQL-PROGRAMMING-CONSTITUTION.md  # Articles I-XVII (binding standards)
│   ├── Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md  # 7 core principles
│   ├── PROJECT-SPECIFICATION.md     # Detailed requirements
│   └── code-analysis/
│       ├── procedures/              # 18 per-procedure analysis documents
│       └── dependency-analysis-*.md # 4 lote + consolidated (68 objects)
├── scripts/
│   ├── automation/                  # 🚧 Python scripts (planned - see README)
│   ├── validation/                  # ✅ check-setup.sh, requirements.txt
│   └── deployment/                  # 🚧 Deployment automation (planned - see README)
├── tests/
│   ├── unit/                        # ✅ 15 test_*.sql files for procedures
│   ├── integration/                 # Cross-object workflow validation
│   └── performance/                 # Performance benchmarks
├── tracking/
│   ├── progress-tracker.md          # Daily sprint status
│   ├── activity-log-YYYY-MM.md      # Session-level logs
│   └── TRACKING-PROCESS.md          # Tracking methodology
├── templates/                       # Object templates (procedure, function, view, test)
└── specs/001-tsql-to-pgsql/        # spec.md, data-model.md, plan.md, tasks.md (317 tasks)
```

---

## 🚀 Quick Start

### Prerequisites

**Required:**
- PostgreSQL 17+ (local or remote)
- AWS Schema Conversion Tool (SCT) - for baseline conversions
- Python 3.10+
- Git
- psql CLI

**Python Automation Packages:**
```bash
pip install -r scripts/automation/requirements.txt
```
Packages: sqlparse, click, pandas, rich, jinja2, pyyaml, beautifulsoup4, lxml, tabulate

**Optional:**
- Claude Code (AI-assisted migration - see [CLAUDE.md](CLAUDE.md))
- GitHub CLI (`gh`)

### Setup Instructions

**New to this project?** Start here:

1. **Environment Validation:**
   ```bash
   ./scripts/validation/check-setup.sh
   ```

2. **Read Core Documentation:**
   - [CLAUDE.md](CLAUDE.md) - AI assistant guidance (v2.0 - 299 lines)
   - [Core Principles](docs/Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md) - 7 binding principles
   - [Constitution](docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md) - Articles I-XVII

3. **Review Dependency Analysis:**
   - [Consolidated Analysis](docs/code-analysis/dependency-analysis-consolidated.md) - All 769 objects + P0 critical path

4. **Explore Completed Work:**
   - [Procedures](source/building/pgsql/refactored/20.%20create-procedure/) - 15 production-ready procedures
   - [Unit Tests](tests/unit/) - 15 test files with comprehensive coverage

---

## 🗺️ Migration Scope

### Object Inventory by Type

**Lote 1 - Stored Procedures** (21 total, 15 migrated ✅)
- 3 P0 critical (AddArc, RemoveArc, ReconcileMUpstream)
- 5 P1 high priority
- 7 P2 medium priority

**Lote 2 - Functions** (25 total)
- 4 P0 critical (McGet* family: upstream, downstream, upstreambylist, downstreambylist)
- 7 P1 high priority (Get* legacy family)
- 8 P2 medium priority
- 4 P3 utility functions

**Lote 3 - Views** (22 total)
- 1 P0 CRITICAL (translated - indexed view → materialized view)
- 3 P1 high priority (upstream, downstream, goo_relationship)
- 10 P2 medium priority
- 6 P3 low priority

**Lote 4 - Types** (1 total)
- 1 P0 CRITICAL (GooList TVP → TEMPORARY TABLE pattern)

**Infrastructure** (715 objects)
- 91 tables (foundation layer)
- 352 indexes (query optimization)
- 271 constraints (data integrity)
- 3 FDW connections (external databases)
- 7 SQL Agent jobs (scheduled operations)

**Total:** 769 database objects

---

## 🔄 Workflow

### Four-Phase Migration Process

**Phase 1: Analysis**
1. Read original T-SQL from `source/original/sqlserver/`
2. Read AWS SCT output from `source/original/pgsql-aws-sct-converted/`
3. Identify P0-P3 issues (categorize by severity)
4. Calculate quality score (must be ≥7.0/10 after corrections)

**Phase 2: Correction**
1. Start with AWS SCT output as baseline
2. Apply 7 core principles (ANSI-SQL primacy, strict typing, set-based execution, etc.)
3. Fix ALL P0 issues (critical blockers)
4. Fix ALL P1 issues (high priority)
5. Add comprehensive error handling
6. Ensure schema-qualified references throughout
7. Save to `source/building/pgsql/refactored/`

**Phase 3: Validation**
1. **Syntax:** Run syntax validation (psql or check script)
2. **Dependencies:** Verify all dependencies resolved
3. **Unit Tests:** Create/update tests in `tests/unit/` (must pass)
4. **Performance:** Run benchmark (within ±20% of SQL Server baseline)
5. **Data Integrity:** Validate row counts, checksums (100% match)

**Phase 4: Deployment**
1. Deploy to DEV environment
2. Run smoke tests in DEV
3. Deploy to STAGING (requires passing DEV)
4. Integration testing in STAGING
5. Deploy to PROD (requires STAGING sign-off + change control)

### Quality Gates

| Environment | Requirements |
|-------------|-------------|
| **DEV** | Can deploy with minor issues (P2/P3) |
| **STAGING** | ZERO P0/P1 issues, all tests passing, ≥7.0/10 quality score |
| **PROD** | STAGING sign-off, ≥8.0/10 target quality score, rollback plan, monitoring |

---

## 📚 Documentation

### Core Standards & Principles

- **[CLAUDE.md](CLAUDE.md)** - AI assistant guidance v2.0 (299 lines, comprehensive)
- **[Constitution](docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md)** - Articles I-XVII (binding law)
- **[7 Core Principles](docs/Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md)** - Quick reference
- **[Project Specification](docs/PROJECT-SPECIFICATION.md)** - Requirements and constraints

### Analysis & Dependencies

- **[Consolidated Analysis](docs/code-analysis/dependency-analysis-consolidated.md)** - All 769 objects, P0 critical path
- **[Lote 1 - Procedures](docs/code-analysis/dependency-analysis-lote1-stored-procedures.md)** - 21 procedures
- **[Lote 2 - Functions](docs/code-analysis/dependency-analysis-lote2-functions.md)** - 25 functions
- **[Lote 3 - Views](docs/code-analysis/dependency-analysis-lote3-views.md)** - 22 views
- **[Lote 4 - Types](docs/code-analysis/dependency-analysis-lote4-types.md)** - 1 type (GooList)
- **[Per-Procedure Analysis](docs/code-analysis/procedures/)** - 18 detailed analysis documents

### Templates & Guides

- **[PostgreSQL Procedure Template](templates/postgresql-procedure-template.sql)** - Production-ready template
- **[Test Templates](templates/)** - Unit test and integration test templates
- **[Tracking Process](tracking/TRACKING-PROCESS.md)** - Activity tracking methodology

### Progress Tracking

- **[Progress Tracker](tracking/progress-tracker.md)** - Current sprint status (update daily)
- **[Activity Log](tracking/activity-log-2026-01.md)** - Session-level activity logs
- **[Sprint Archives](tracking/)** - Historical sprint data

---

## 🤝 Contributing

### Git Commit Conventions

We use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Examples
git commit -m "feat: add corrected view v_material_lineage"
git commit -m "fix: correct FK constraint in transition_material table"
git commit -m "docs: update dependency analysis for lote3 views"
git commit -m "test: add edge case tests for mcgetupstream function"
git commit -m "perf: optimize index on goo.parent_goo_id"
```

**Commit Types:**
- `feat:` - New object migration/conversion
- `fix:` - Bug fix in corrected object
- `docs:` - Documentation update
- `test:` - Add or update tests
- `perf:` - Performance optimization
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

---

## 🎯 Next Steps

### Immediate (Next Phase)

1. ✅ **Phase 1 Complete:** 15/15 stored procedures migrated
2. 🔴 **Phase 2 Priority:** P0 Critical Path (9 objects)
   - VIEW `translated` (materialized view with trigger refresh)
   - TYPE `GooList` (TEMPORARY TABLE pattern decision)
   - FUNCTIONS McGet* family (4 functions)
   - TABLES foundation (3 tables: goo, material_transition, transition_material)
3. 🔴 **Phase 3:** P1 High Priority Objects (18 objects)
   - Legacy Get* function family (7 functions)
   - Supporting views (3 views: upstream, downstream, goo_relationship)
   - P1 procedures dependencies
4. 🔴 **Phase 4:** Infrastructure (tables, indexes, constraints)
5. 🔴 **Phase 5:** FDW connections and SQL Agent jobs

### Phase 2 Goals (Weeks 5-8)

- Complete P0 critical path (9 objects)
- Validate `translated` materialized view refresh strategy
- Implement GooList TEMPORARY TABLE pattern
- Migrate McGet* function family
- Enable foundation tables for all dependencies
- Maintain quality targets (≥8.0/10 average)
- Apply pattern reuse for 5-6× velocity

---

## 📞 Contact

**Project Lead:** Pierre Ribeiro
**Role:** Senior DBA/DBRE + Data Engineer
**Company:** DinamoTech
**Location:** Rio de Janeiro, Brazil
**GitHub:** [@pierreribeiro](https://github.com/pierreribeiro)

---

## 🙏 Acknowledgments

- **AWS Schema Conversion Tool** - Baseline conversion (~70% automation)
- **Claude (Anthropic)** - AI-assisted analysis, code review, and migration guidance
- **PostgreSQL Community** - Excellent documentation and support
- **Claude Code** - Integrated development environment for AI-assisted coding

---

**Project Version:** 2.0.0
**Last Updated:** 2026-01-22
**Current Status:** ✅ Phase 1 Complete (15/15 Procedures) | 🔄 Phase 2 Ready (P0 Critical Path)
**Overall Progress:** 2% (15/769 objects complete)
**Next Milestone:** P0 Critical Path (9 objects: 1 view, 1 type, 4 functions, 3 tables)

---

Made with ❤️ by Pierre Ribeiro @ DinamoTech
