# PostgreSQL Build Directory

## Purpose

PostgreSQL-specific build directory containing production-ready refactored objects.

## Structure

```
pgsql/
└── refactored/         # Production-ready PostgreSQL objects (0-21 dependency-ordered)
```

## Contents

### Directories

- **refactored/** - Production-ready PostgreSQL objects (15/769 objects complete)

### Files

- `.DS_Store` - macOS metadata (ignored by git)

## Workflow

Objects progress through this structure:
1. **Copy** AWS SCT baseline from `source/original/pgsql-aws-sct-converted/`
2. **Correct** in `refactored/` subdirectory
3. **Validate** with syntax, dependency, performance tests
4. **Deploy** to DEV → STAGING → PROD

## Navigation

- Up: [../README.md](../README.md)
- See: [refactored/README.md](refactored/README.md) for production-ready objects

---

**Last Updated:** 2026-01-22 | **Status:** 15/769 objects production-ready (2%)
