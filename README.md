# SQL Server → PostgreSQL Migration Project
## Perseus Database Stored Procedures Conversion

[![Project Status](https://img.shields.io/badge/status-in--progress-yellow)](https://github.com)
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

This project manages the conversion of **15+ stored procedures** from SQL Server (T-SQL) to PostgreSQL (PL/pgSQL) for the Perseus database. The conversion leverages AWS Schema Conversion Tool (SCT) as a baseline, with mandatory manual review and correction to ensure production quality.

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
├── procedures/                  # Procedure files (original, converted, corrected)
├── scripts/                     # Automation scripts
├── templates/                   # Templates
├── tests/                       # Test suite
├── tracking/                    # Project tracking
└── .github/workflows/          # CI/CD pipelines
```

---

## 📊 Current Status

### Overall Progress

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Procedures** | 15 | 100% |
| **Analyzed** | 1 | 7% |
| **Corrected** | 0 | 0% |
| **In Testing** | 0 | 0% |
| **Deployed to DEV** | 0 | 0% |
| **Deployed to PROD** | 0 | 0% |

**Last Updated:** 2025-11-12

### By Priority

| Priority | Total | Completed | Remaining |
|----------|-------|-----------|-----------|
| **P1** (Critical, High Complexity) | 6 | 0 | 6 |
| **P2** (Low Crit, Low Complexity) | 6 | 0 | 6 |
| **P3** (Low Crit, High Complexity) | 3 | 0 | 3 |

### Current Sprint: Sprint 0 (Setup)

**Goal:** Establish project infrastructure

**Tasks:**
- [x] Create repository structure
- [x] Create project plan
- [x] Create priority matrix
- [ ] Extract all procedures from SQL Server
- [ ] Run AWS SCT on all procedures
- [ ] Complete procedure inventory
- [ ] Set up CI/CD pipeline

**Next Sprint:** Sprint 1 (High Priority Procedures) - Start Date: TBD

---

## 📚 Documentation

### Key Documents

- **[Project Plan](docs/PROJECT-PLAN.md)** - Complete project plan with roadmap
- **[Priority Matrix](tracking/priority-matrix.csv)** - Procedure prioritization
- **[Progress Tracker](tracking/progress-tracker.md)** - Current status

### Procedure Documentation

Each procedure has detailed analysis in `procedures/analysis/{procedure}-analysis.md`

**Example:** [ReconcileMUpstream Analysis](procedures/analysis/reconcilemupstream-analysis.md)

---

## 🤝 Contributing

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New procedure correction
- `fix:` Bug fix in corrected procedure
- `docs:` Documentation update
- `test:` Add or update tests
- `chore:` Maintenance tasks

---

## 📞 Contact

**Project Lead:** Pierre Ribeiro  
**Company:** DinamoTech  
**Location:** Rio de Janeiro, Brazil  
**GitHub:** [@pierreribeiro](https://github.com/pierreribeiro)

---

## 🙏 Acknowledgments

- **AWS Schema Conversion Tool** - Baseline conversion
- **Claude (Anthropic)** - AI-assisted analysis
- **PostgreSQL Community** - Excellent documentation

---

**Last Updated:** 2025-11-12  
**Version:** 1.0.0  
**Status:** 🟢 Active Development

---

Made with ❤️ by Pierre Ribeiro @ DinamoTech