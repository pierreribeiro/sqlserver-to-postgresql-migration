# SQL Server → PostgreSQL Migration Project
## Perseus Database Stored Procedures Conversion

[![Project Status](https://img.shields.io/badge/status-sprint--3--complete-green)](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-blue)](https://www.postgresql.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2014-red)](https://www.microsoft.com/sql-server)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> **Mission:** Systematically convert, validate, and deploy all Perseus SQL Server stored procedures to PostgreSQL with zero production incidents.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Quick Start](#-quick-start)
- [Repository Structure](#-repository-structure)
- [Workflow](#-workflow)
- [Current Status](#-current-status)
- [Contributing](#-contributing)
- [Documentation](#-documentation)
- [Contact](#-contact)

---

## 🎯 Project Overview

### Background

This project manages the conversion of **15 stored procedures** from SQL Server (T-SQL) to PostgreSQL (PL/pgSQL) for the Perseus database. The conversion leverages AWS Schema Conversion Tool (SCT) as a baseline, with mandatory manual review and correction to ensure production quality.

### Objectives

- ✅ Convert all Perseus procedures to PostgreSQL
- ✅ Maintain or improve performance (within 20% of SQL Server baseline)
- ✅ Zero production bugs (P0) in first 30 days
- ✅ Complete documentation and operational runbooks
- ✅ Team trained on new procedures

### Approach

**Three-Phase Strategy:**

1. **AWS SCT Conversion** - Automated baseline (~70% complete)
2. **Manual Review & Correction** - Critical fixes and optimizations (~30%)
3. **Validation & Deployment** - Testing, staging, production rollout

**Quality First:** Every procedure goes through analysis, correction, validation, and deployment phases with defined quality gates.

---

## 🚀 Quick Start

### 📖 Setup Instructions

**New to this project?** Start here:

1. **[SETUP-GUIDE.md](docs/SETUP-GUIDE.md)** - Complete environment setup (15-30 min)
2. **[PROJECT-PLAN.md](docs/PROJECT-PLAN.md)** - Full 10-week roadmap
3. **Run Setup Validation:**
   ```bash
   ./scripts/validation/check-setup.sh
   ```

### Prerequisites

**Required:**
- PostgreSQL 16+ (local or remote)
- AWS Schema Conversion Tool (SCT)
- Python 3.10+
- Git
- psql CLI

**Python Automation Packages** (install via pip):
- Run: `pip install -r scripts/automation/requirements.txt`
- Packages: sqlparse, click, pandas, rich, jinja2, pyyaml, etc.

**Optional:**
- Claude Desktop (for AI-assisted analysis)
- GitHub CLI (`gh`) - See [SETUP-GUIDE.md](docs/SETUP-GUIDE.md) for installation

---

## 📁 Repository Structure

```
sqlserver-to-postgresql-migration/
├── README.md                    # This file
├── docs/                        # Project documentation
│   └── PROJECT-PLAN.md         # ✅ Complete 10-week plan
├── procedures/                  
│   ├── original/               # ✅ 15 T-SQL procedures
│   ├── aws-sct-converted/      # ✅ 16 files (15 procedures + README)
│   ├── corrected/              # Production-ready versions
│   └── analysis/               # ✅ 1 complete (ReconcileMUpstream)
├── scripts/                     # Automation scripts
├── templates/                   # ✅ PostgreSQL template + guides
├── tests/                       # Test suite
├── tracking/                    # ✅ Priority matrix + progress
└── .github/workflows/          # CI/CD pipelines
```

---

## 📊 Current Status

### Overall Progress - **Sprint 3: COMPLETE** 🎉

| Phase | Status | Completion |
|-------|--------|------------|
| **Sprint 0 (Setup)** | ✅ Complete | **100%** ✅ |
| **Sprint 3 (Arc Operations + Tree Processing)** | ✅ Complete | **100%** ✅ |
| Sprint 1-2 (P1 Procedures) | 🟡 In Progress | 30% |
| Sprint 4-6 (P2 Procedures) | ⚪ Not Started | 0% |
| Sprint 7-8 (P3 Procedures) | ⚪ Not Started | 0% |
| Sprint 9 (Integration) | ⚪ Not Started | 0% |
| Sprint 10 (Production) | ⚪ Not Started | 0% |

### Sprint 3 Status (Week 4) - ✅ COMPLETE

| Issue | Procedure | Status | Quality | Hours | Date |
|-------|-----------|--------|---------|-------|------|
| #18 | AddArc | ✅ Done | 8.5/10 ⭐ | 2h | 2025-11-24 |
| #19 | RemoveArc | ✅ Done | 9.0/10 ⭐⭐ | 0.5h | 2025-11-24 |
| #20 | ProcessDirtyTrees | ✅ Done | 8.5/10 ⭐ | 1.5h | 2025-11-24 |

**Sprint 3 Achievements:**
- ✅ **100% completion** (3 of 3 procedures delivered)
- ⚡ **5-6× faster than estimated** (4h actual vs 22-26h estimated)
- ⭐ **Quality: 8.67/10 average** (exceeds 8.0-8.5 target)
- 📈 **Performance: +63-97% average** (far exceeds ±20% target)
- 🔧 **4 P0 critical blockers fixed** (prevented production failures)
- 🧪 **34+ test scenarios created** (comprehensive coverage)

---

## 📈 Procedure Inventory

### By Priority

| Priority | Count | Description |
|----------|-------|-------------|
| **P1** (Critical, High Complexity) | 6 | Plan carefully, execute early |
| **P2** (Low Criticality, Low Complexity) | 6 | Filler work, easier wins |
| **P3** (Low Criticality, High Complexity) | 3 | Defer until later sprints |
| **TOTAL** | **15** | All procedures extracted ✅ |

### Analysis Status

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Procedures** | 15 | 100% |
| **Extracted from SQL Server** | 15 | 100% ✅ |
| **AWS SCT Converted** | 15 | 100% ✅ |
| **Analyzed** | 4 | 27% |
| **Corrected** | 3 | 20% ✅ |
| **In Testing** | 3 | 20% |
| **Deployed to DEV** | 0 | 0% |

**Last Updated:** 2025-11-24

**Corrected Procedures:**
- ✅ AddArc (Quality: 8.5/10, Perf: +90%, Sprint 3)
- ✅ RemoveArc (Quality: 9.0/10, Perf: +50-100%, Sprint 3)
- ✅ ProcessDirtyTrees (Quality: 8.5/10, 4 P0 fixed, Sprint 3)

**Analyzed (Pending Correction):**
- ✅ ReconcileMUpstream (Quality: 6.6/10, P1 priority, Sprint 2)

---

## 📚 Documentation

### Key Documents

- **[Setup Guide](docs/SETUP-GUIDE.md)** - Environment setup & configuration ✅
- **[Project Plan](docs/PROJECT-PLAN.md)** - Complete 10-week roadmap ✅
- **[Priority Matrix](tracking/priority-matrix.csv)** - Procedure prioritization ✅
- **[Progress Tracker](tracking/progress-tracker.md)** - Current status ✅
- **[Sprint 3 Retrospective](docs/sprint3-retrospective.md)** - Complete analysis & learnings ✅
- **[PostgreSQL Template](templates/postgresql-procedure-template.sql)** - Production-ready template ✅

### Analysis & Corrections

- **[ReconcileMUpstream Analysis](procedures/analysis/reconcilemupstream-analysis.md)** - 6.6/10 quality ✅
- **[AddArc Corrected](procedures/corrected/addarc.sql)** - 8.5/10 quality ✅
- **[RemoveArc Corrected](procedures/corrected/removearc.sql)** - 9.0/10 quality ✅
- **[ProcessDirtyTrees Corrected](procedures/corrected/processdirtytrees.sql)** - 8.5/10 quality ✅

### Test Suites

- **[AddArc Tests](tests/unit/test_addarc.sql)** - 7 test cases ✅
- **[RemoveArc Tests](tests/unit/test_removearc.sql)** - 7+ test cases ✅
- **[ProcessDirtyTrees Tests](tests/unit/test_processdirtytrees.sql)** - 20+ test scenarios ✅

### Available Resources

- ✅ 15 original T-SQL procedures
- ✅ 15 AWS SCT converted procedures
- ✅ 3 corrected procedures (production-ready)
- ✅ 34+ comprehensive test scenarios
- ✅ Complete project infrastructure
- ✅ PostgreSQL procedure template with best practices
- ✅ 5 established patterns (transaction, validation, performance, temp tables, refcursor)
- ✅ Sprint 3 retrospective with learnings

---

## 🤝 Contributing

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New procedure correction
- `fix:` Bug fix in corrected procedure
- `docs:` Documentation update
- `test:` Add or update tests
- `chore:` Maintenance tasks

**Example:**
```bash
git commit -m "feat: correct ReconcileMUpstream with P0 fixes"
git commit -m "docs: update Sprint 0 completion status"
```

---

## 🎯 Next Steps

### Immediate (Next Sprint)

1. ✅ ~~Sprint 3 Complete~~ **DONE** (AddArc, RemoveArc, ProcessDirtyTrees)
2. 🔴 **Sprint 4 Priority:** Complete Sprint 2 Dependencies
   - ProcessSomeMUpstream (8h est → 2-3h with patterns)
   - ReconcileMUpstream (8h est → 2-3h with patterns)
   - usp_UpdateMUpstream (8h est → 2-3h with patterns)
   - usp_UpdateMDownstream (8h est → 2-3h with patterns)
3. 🔴 **Integration Testing:** Validate ProcessDirtyTrees with dependencies
4. 🔴 **Documentation:** Create dependency graph visualization
5. 🔴 **Begin Sprint 5:** Continue P1 procedures

### Sprint 4 Goals (Week 5-6)

- Complete Sprint 2 dependencies (4 procedures)
- Enable ProcessDirtyTrees integration tests
- Leverage pattern reuse for 5-6× velocity
- Maintain quality targets (8.0-8.5/10)
- Document dependency chains

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
- **Claude (Anthropic)** - AI-assisted analysis and code review
- **PostgreSQL Community** - Excellent documentation and support

---

**Project Version:** 1.3.0
**Last Updated:** 2025-11-24
**Sprint Status:** ✅ Sprint 3 - 100% Complete
**Next Milestone:** Sprint 4 Start (Sprint 2 Dependencies)

---

Made with ❤️ by Pierre Ribeiro @ DinamoTech