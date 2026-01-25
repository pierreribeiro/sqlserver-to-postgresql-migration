# Building Directory

## Purpose

Work-in-progress and production-ready PostgreSQL code. Contains corrected, validated, and deployment-ready database objects.

## Structure

```
building/
└── pgsql/                  # PostgreSQL-specific builds
    └── refactored/         # Production-ready objects (0-21 dependency-ordered)
```

## Contents

### Directories

- **pgsql/** - PostgreSQL database objects (only target platform currently)
  - **refactored/** - Production-ready code (15/769 objects complete)

### Files

- (No files at this level - all code organized in subdirectories)

## Status

| Object Type | Complete | Pending | Progress |
|-------------|----------|---------|----------|
| **Procedures** | 15 ✅ | 0 | 100% |
| **Functions** | 0 | 25 | 0% |
| **Views** | 0 | 22 | 0% |
| **Tables** | 0 | 91 | 0% |
| **Indexes** | 0 | 352 | 0% |
| **Constraints** | 0 | 271 | 0% |
| **Other** | 0 | 3 | 0% |
| **TOTAL** | **15** | **754** | **2%** |

## Quality Standards

All code in this directory MUST meet:
- ✅ Quality score ≥7.0/10 (target ≥8.0/10)
- ✅ Performance within ±20% of SQL Server baseline
- ✅ Zero P0/P1 issues
- ✅ All 7 core principles compliant
- ✅ Comprehensive unit tests passing
- ✅ Schema-qualified object references
- ✅ Proper error handling

## Workflow

Objects move through this directory:
1. **Copy** AWS SCT baseline to `refactored/`
2. **Correct** P0-P3 issues, apply 7 core principles
3. **Validate** syntax, dependencies, tests, performance
4. **Deploy** to DEV → STAGING → PROD
5. **Monitor** performance and quality metrics

## Navigation

- See [pgsql/README.md](pgsql/README.md) for PostgreSQL objects

---

**Last Updated:** 2026-01-22 | **Status:** 15/769 objects (2%) production-ready
