# SQL Server → PostgreSQL Migration Project
## Perseus Database Stored Procedures Conversion

[![Project Status](https://img.shields.io/badge/status-sprint--0--75%25-yellow)](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration)
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

See [PROJECT-PLAN.md](docs/PROJECT-PLAN.md) for complete setup instructions.

### Prerequisites

**Required:**
- PostgreSQL 16+ (local or remote)
- AWS Schema Conversion Tool (SCT)
- Python 3.10+
- Git
- psql CLI

**Optional:**
- Claude Desktop (for AI-assisted analysis)
- GitHub CLI

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

### Overall Progress - **Sprint 0: 75% Complete** 🎉

| Phase | Status | Completion |
|-------|--------|------------|
| **Sprint 0 (Setup)** | 🟡 In Progress | **75%** ✅ |
| Sprint 1-3 (P1 Procedures) | ⚪ Not Started | 0% |
| Sprint 4-6 (P2 Procedures) | ⚪ Not Started | 0% |
| Sprint 7-8 (P3 Procedures) | ⚪ Not Started | 0% |
| Sprint 9 (Integration) | ⚪ Not Started | 0% |
| Sprint 10 (Production) | ⚪ Not Started | 0% |

### Sprint 0 Status (Week 1)

| Task | Status | Date |
|------|--------|------|
| Create GitHub repository | ✅ Done | 2025-11-12 |
| Set up directory structure | ✅ Done | 2025-11-13 |
| Extract all procedures from SQL Server | ✅ Done | 2025-11-13 |
| Run AWS SCT on all procedures | ✅ Done | 2025-11-13 |
| Calculate priority matrix | ✅ Done | 2025-11-13 |
| Create PostgreSQL template | ✅ Done | 2025-11-13 |
| Create Claude Project | 🔴 Pending | Target: 11/14 |
| Complete inventory validation | 🔴 Pending | Target: 11/15 |

**Major Achievements:**
- 🎉 All 15 source procedures extracted
- 🎉 AWS SCT batch conversion completed (16 files)
- 🎉 Real LOC data collected and validated
- 🎉 Production-ready template created

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
| **Analyzed** | 1 | 7% |
| **Corrected** | 0 | 0% |
| **In Testing** | 0 | 0% |
| **Deployed to DEV** | 0 | 0% |

**Last Updated:** 2025-11-13

**Analyzed Procedure:**
- ✅ ReconcileMUpstream (Quality Score: 6.6/10, P1 priority)

---

## 📚 Documentation

### Key Documents

- **[Project Plan](docs/PROJECT-PLAN.md)** - Complete 10-week roadmap ✅
- **[Priority Matrix](tracking/priority-matrix.csv)** - Procedure prioritization ✅
- **[Progress Tracker](tracking/progress-tracker.md)** - Current status
- **[PostgreSQL Template](templates/postgresql-procedure-template.sql)** - Production-ready template ✅
- **[ReconcileMUpstream Analysis](procedures/analysis/reconcilemupstream-analysis.md)** - First complete analysis ✅

### Available Resources

- ✅ 15 original T-SQL procedures
- ✅ 15 AWS SCT converted procedures
- ✅ Complete project infrastructure
- ✅ PostgreSQL procedure template with best practices
- ✅ Priority matrix with criticality/complexity scoring
- ✅ First procedure analysis as reference

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

### Immediate (This Week)

1. ✅ ~~Extract all procedures~~ **DONE**
2. ✅ ~~Run AWS SCT batch conversion~~ **DONE**
3. 🔴 Create Claude Project (Wed 11/14)
4. 🔴 Validate inventory (Thu 11/15)
5. 🔴 Begin Sprint 1 (Mon 11/19)

### Sprint 1 Goals (Week 2)

- Select first 2 P1 procedures
- Complete analysis using template
- Apply corrections
- Deploy to DEV
- Establish conversion rhythm

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

**Project Version:** 1.1.0  
**Last Updated:** 2025-11-13  
**Sprint Status:** 🟡 Sprint 0 - 75% Complete  
**Next Milestone:** Sprint 1 Start (2025-11-19)

---

Made with ❤️ by Pierre Ribeiro @ DinamoTech