# Documentation Directory

## Purpose

Comprehensive project documentation for Perseus SQL Server → PostgreSQL 17+ migration covering standards, specifications, analysis, and best practices.

## Structure

```
docs/
├── code-analysis/                       # Per-object analysis and dependency mappings
├── POSTGRESQL-PROGRAMMING-CONSTITUTION.md  # Articles I-XVII (binding standards)
├── Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md  # 7 core principles
├── PROJECT-SPECIFICATION.md             # Detailed requirements and constraints
├── Project-History.md                   # Project evolution and decisions
└── fdw-production-best-practices-research.md  # FDW integration research
```

## Contents

### Core Standards & Principles

- **[POSTGRESQL-PROGRAMMING-CONSTITUTION.md](POSTGRESQL-PROGRAMMING-CONSTITUTION.md)** (44 KB) - Articles I-XVII defining binding programming standards for all PostgreSQL code. Covers syntax, types, transactions, naming, error handling, and quality frameworks.

- **[Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md](Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md)** (1.6 KB) - Quick reference for 7 mandatory principles: ANSI-SQL primacy, strict typing, set-based execution, atomic transactions, idiomatic naming, error resilience, modular separation.

### Project Documentation

- **[PROJECT-SPECIFICATION.md](PROJECT-SPECIFICATION.md)** (25 KB) - Comprehensive requirements document covering scope (769 objects), quality standards, workflows, validation criteria, and deployment gates.

- **[Project-History.md](Project-History.md)** (5.3 KB) - Project evolution timeline, key decisions, and milestone achievements.

### Research & Best Practices

- **[fdw-production-best-practices-research.md](fdw-production-best-practices-research.md)** (54 KB) - PostgreSQL Foreign Data Wrapper (FDW) implementation guide for migrating SQL Server linked servers (hermes, sqlapps, deimeter).

### Analysis Artifacts

- **[code-analysis/](code-analysis/)** - Per-procedure analysis documents and dependency mappings for all 769 objects across 4 lotes (procedures, functions, views, types).

## Document Categories

### Standards (MANDATORY Reading)

**Before making ANY code changes, read:**
1. `.specify/memory/constitution.md` - 7 binding core principles
2. `POSTGRESQL-PROGRAMMING-CONSTITUTION.md` - Detailed standards
3. `Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md` - Quick reference

### Requirements & Specifications

**For project understanding:**
- `PROJECT-SPECIFICATION.md` - Complete requirements
- `Project-History.md` - Evolution and context

### Technical Guides

**For specific migrations:**
- `fdw-production-best-practices-research.md` - FDW patterns
- `code-analysis/` - Object-specific analysis

## Navigation

- See [code-analysis/README.md](code-analysis/README.md) for dependency analysis documents
- Up: [../README.md](../README.md)

---

**Last Updated:** 2026-01-22 | **Documents:** 6 core files + analysis subdirectory
