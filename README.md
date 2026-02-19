# SQL Server → PostgreSQL Migration Project
## Perseus Database Complete Migration

[![Project Status](https://img.shields.io/badge/status-US1%20views%20in%20progress-blue)](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17+-blue)](https://www.postgresql.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2014-red)](https://www.microsoft.com/sql-server)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Objects](https://img.shields.io/badge/objects-769-orange)](docs/code-analysis/dependency/dependency-analysis-consolidated.md)
[![Procedures](https://img.shields.io/badge/procedures-15%2F15-success)](source/building/pgsql/refactored/20.create-procedure/)
[![Tables](https://img.shields.io/badge/tables-94%2F94-success)](source/building/pgsql/refactored/14.create-table/)
[![Progress](https://img.shields.io/badge/progress-14%25-yellow)](tracking/progress-tracker.md)

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
- ✅ **15 Stored Procedures** (COMPLETE — avg 8.67/10, +63-97% performance)
- ✅ **94 Tables** (COMPLETE — deployed to DEV)
- ⚠️ **213 Indexes** (175/213 deployed — column mismatches pending)
- ⚠️ **270 Constraints** (230/270 deployed — column mismatches pending)
- 🔄 **22 Views** (US1 in progress — dependency analysis complete, T031-T033 ✅)
- 🔄 **25 Functions** (15 table-valued, 10 scalar — US2, after US1)
- 🔄 **1 UDT** (GooList → TEMPORARY TABLE pattern)
- 🔄 **3 FDW Connections** (hermes, sqlapps, deimeter — 17 foreign tables)
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

### Overall Progress

| Object Type | Total | Complete | In Progress | Pending | Status |
|-------------|-------|----------|-------------|---------|--------|
| **Stored Procedures** | 15 | 15 ✅ | — | 0 | **COMPLETE** |
| **Tables** | 94 | 94 ✅ | — | 0 | **COMPLETE** |
| **Indexes** | 213 | 175 ✅ | — | 38 | ⚠️ Column mismatches pending |
| **Constraints** | 270 | 230 ✅ | — | 40 | ⚠️ Column mismatches pending |
| **Views** | 22 | 0 | 🔄 US1 | 22 | US1 started — T031-T033 done |
| **Functions** | 25 | 0 | — | 25 | US2 (after US1) |
| **UDT (GooList)** | 1 | 0 | — | 1 | Pending |
| **FDW Connections** | 3 | 0 | — | 3 | Pending |
| **SQL Agent Jobs** | 7 | 0 | — | 7 | Pending |
| **TOTAL** | **769** | **109** | — | **660** | **~14% Complete** |

**Last Updated:** 2026-02-19

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

**All 15 procedures** are production-ready in [source/building/pgsql/refactored/20.create-procedure/](source/building/pgsql/refactored/20.create-procedure/)

### Critical Path (P0 Objects)

| Object | Type | Status | Notes |
|--------|------|--------|-------|
| `translated` | Materialized View | 🔄 US1 | Indexed view → `CREATE MATERIALIZED VIEW` + pg_cron refresh |
| `mcgetupstream` | Function | Pending | Depends on `translated` view |
| `mcgetdownstream` | Function | Pending | Depends on `translated` view |
| `mcgetupstreambylist` | Function | Pending | Depends on `translated` view |
| `mcgetdownstreambylist` | Function | Pending | Depends on `translated` view |
| `goo` | Table | ✅ DEV | Deployed to DEV |
| `material_transition` | Table | ✅ DEV | Deployed to DEV |
| `transition_material` | Table | ✅ DEV | Deployed to DEV |

---

## 📁 Repository Structure

```
sqlserver-to-postgresql-migration/
├── README.md                     # This file
├── CLAUDE.md                     # AI assistant guidance (v2.1)
├── source/
│   ├── original/
│   │   ├── sqlserver/            # 822 files — Original T-SQL (0-21 dependency-ordered)
│   │   └── pgsql-aws-sct-converted/  # 1,385 files — AWS SCT baseline (~70% complete)
│   └── building/pgsql/refactored/   # Production-ready PostgreSQL (0-21 dependency-ordered)
│       ├── 14.create-table/      # ✅ 94 tables COMPLETE
│       ├── 15.create-view/       # 🔄 US1 in progress (MIGRATION-SEQUENCE.md ✅)
│       ├── 16.create-index/      # ⚠️ 175/213 deployed
│       ├── 17.create-constraint/ # ⚠️ 230/270 deployed
│       ├── 19.create-function/   # Pending (25 functions — US2)
│       ├── 20.create-procedure/  # ✅ 15 procedures COMPLETE
│       └── 21.create-trigger/    # Pending
├── docs/
│   ├── backups/                  # Versioned backups (CLAUDE.md, README.md)
│   ├── code-analysis/
│   │   ├── dependency/           # dependency-analysis-*.md (4 lote + consolidated)
│   │   ├── procedures/           # Per-procedure analysis (15 documents)
│   │   └── tables/               # Per-table analysis documents
│   ├── db-design/
│   │   ├── pgsql/                # Data dictionary, ER diagrams, type reference
│   │   └── sqlserver/            # TABLE-CATALOG.md, original ER diagrams
│   ├── data-assessments/         # Row counts, constraint CSVs
│   ├── plans/                    # Action plans (pre-staging, pre-prod)
│   ├── POSTGRESQL-PROGRAMMING-CONSTITUTION.md  # Articles I-XVII (binding)
│   └── PROJECT-SPECIFICATION.md  # Requirements and constraints
├── scripts/
│   ├── automation/               # 🚧 Python automation (planned)
│   ├── validation/               # ✅ check-setup.sh, dependency-check.sql
│   └── deployment/               # 🚧 Deployment automation (planned)
├── tests/
│   ├── unit/                     # ✅ 15 procedure tests + views/ (US1 pending)
│   ├── integration/              # Cross-object workflow validation
│   └── performance/              # Performance benchmarks
├── tracking/
│   ├── progress-tracker.md       # Sprint status (update daily)
│   └── activity-log-YYYY-MM.md   # Session-level logs
├── templates/                    # Object templates (procedure, function, view, test)
└── specs/001-tsql-to-pgsql/     # spec.md, tasks.md (317 tasks), WORKFLOW-GUIDE.md
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

- **[CLAUDE.md](CLAUDE.md)** - AI assistant guidance v2.1 (CLI tools, MCP servers, workflow)
- **[Constitution](docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md)** - Articles I-XVII (binding)
- **[7 Core Principles](docs/Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md)** - Quick reference
- **[Project Specification](docs/PROJECT-SPECIFICATION.md)** - Requirements and constraints
- **[Workflow Guide](specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md)** - Mandatory US execution workflow

### Analysis & Dependencies

- **[Consolidated Analysis](docs/code-analysis/dependency/dependency-analysis-consolidated.md)** - All 769 objects, P0 critical path
- **[Lote 3 - Views](docs/code-analysis/dependency/dependency-analysis-lote3-views.md)** - 22 views (US1 active)
- **[Lote 2 - Functions](docs/code-analysis/dependency/dependency-analysis-lote2-functions.md)** - 25 functions (US2)
- **[Lote 1 - Procedures](docs/code-analysis/dependency/dependency-analysis-lote1-stored-procedures.md)** - 15 procedures (complete)
- **[Lote 4 - Types](docs/code-analysis/dependency/dependency-analysis-lote4-types.md)** - 1 type (GooList)

### DB Design

- **[PostgreSQL Data Dictionary](docs/db-design/pgsql/perseus-data-dictionary.md)** - Schema reference
- **[Type Transformation Reference](docs/db-design/pgsql/TYPE-TRANSFORMATION-REFERENCE.md)** - SQL Server → PostgreSQL type mapping
- **[SQL Server Table Catalog](docs/db-design/sqlserver/TABLE-CATALOG.md)** - Original 94-table catalog
- **[DB Design Index](docs/db-design/INDEX.md)** - All design documents

### View Migration (US1 Active)

- **[Migration Sequence](source/building/pgsql/refactored/15.create-view/MIGRATION-SEQUENCE.md)** - Dependency-ordered 3-wave plan (T033 ✅)

### Templates & Progress

- **[Templates](templates/)** - Procedure, function, view, test templates
- **[Progress Tracker](tracking/progress-tracker.md)** - Sprint status (update daily)
- **[Activity Logs](tracking/)** - Session-level logs and sprint archives
- **[Backups](docs/backups/)** - Versioned backups of key documentation

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

### Active Work

- 🔄 **US1 (Views):** Branch `us1-critical-views` — T031-T033 ✅, Phase 1 Analysis (T034-T038) next
- ⚠️ **Indexes/Constraints:** 38 indexes + 40 constraints pending (column mismatch fixes)

### Up Next

1. **US1 — Phase 1 Analysis (T034-T038):** Analyze all 22 views via Ralph Loop (parallel batch)
2. **US1 — Phase 2 Refactoring (T040-T046):** `translated` materialized view + 21 standard views
3. **US1 — Phase 3 Validation + Phase 4 Deployment (T047-T062)**
4. **US2 — Functions (25):** McGet* family (P0), Get* legacy family (P1) — starts after US1
5. **Index/Constraint fixes:** Resolve remaining column mismatches

### Quality Targets

- Minimum: ≥7.0/10 per object, no dimension below 6.0/10
- Production target: ≥8.0/10 average (achieved 8.67/10 for procedures)

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

**Project Version:** 2.1.0
**Last Updated:** 2026-02-19
**Current Status:** ✅ Procedures (15/15) | ✅ Tables (94/94) | 🔄 US1 Views in progress | ⚠️ Indexes/Constraints partial
**Overall Progress:** ~14% (109/769 objects fully complete)
**Next Milestone:** US1 Phase 1 Analysis — T034-T038 (22 views batch analysis via Ralph Loop)

---

Made with ❤️ by Pierre Ribeiro @ DinamoTech
