# Source Code Directory

## Purpose

Contains ALL source code for the Perseus database migration: original T-SQL from SQL Server, AWS SCT converted baseline, and production-ready PostgreSQL refactored objects.

## Structure

```
source/
├── original/              # Original source code (read-only reference)
│   ├── sqlserver/         # 822 T-SQL files from SQL Server 2014
│   └── pgsql-aws-sct-converted/  # 1,385 AWS SCT baseline files (~70% complete)
└── building/              # Work-in-progress and production-ready code
    └── pgsql/
        └── refactored/    # Production-ready PostgreSQL objects (0-21 dependency-ordered)
```

## Contents

### Directories

- **original/** - Original source code from SQL Server + AWS SCT baseline (READ-ONLY)
- **building/** - Production PostgreSQL code being built and deployed

### Files

- (No files at this level - all code organized in subdirectories)

## Workflow

1. **Reference** original T-SQL from `original/sqlserver/`
2. **Review** AWS SCT conversion baseline from `original/pgsql-aws-sct-converted/`
3. **Correct** and save production-ready code to `building/pgsql/refactored/`
4. **Deploy** from `building/pgsql/refactored/` to DEV → STAGING → PROD

## Key Metrics

| Category | SQL Server Original | AWS SCT Converted | PostgreSQL Refactored |
|----------|---------------------|-------------------|-----------------------|
| **Total Files** | 822 | 1,385 | 15 (procedures only) |
| **Procedures** | 21 | 16 | 15 ✅ |
| **Functions** | 24 | 48 | 0 (pending) |
| **Views** | 22 | 22 | 0 (pending) |
| **Tables** | 101 | 101 | 0 (pending) |
| **Other Objects** | 654 | 1,198 | 0 (pending) |

## Navigation

- See [original/README.md](original/README.md) for source references
- See [building/README.md](building/README.md) for production code

---

**Last Updated:** 2026-01-22
