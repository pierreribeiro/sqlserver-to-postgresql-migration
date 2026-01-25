# Original Source Code (READ-ONLY)

## Purpose

READ-ONLY reference directory containing original T-SQL from SQL Server 2014 and AWS Schema Conversion Tool (SCT) baseline output. Used for comparison, analysis, and as conversion baseline.

## Structure

```
original/
├── sqlserver/                  # 822 files - Original T-SQL (0-21 dependency-ordered)
└── pgsql-aws-sct-converted/    # 1,385 files - AWS SCT baseline (~70% complete)
```

## Contents

### Directories

- **sqlserver/** - 822 original T-SQL files extracted from SQL Server 2014 Perseus database
- **pgsql-aws-sct-converted/** - 1,385 AWS SCT converted files (baseline for manual correction)

### Files

- (No files at this level - all code organized by type in subdirectories)

## Usage

**DO:**
- ✅ Read original T-SQL for business logic understanding
- ✅ Compare AWS SCT output with original to identify conversion issues
- ✅ Use as baseline for creating corrected PostgreSQL versions

**DO NOT:**
- ❌ Modify files in this directory (READ-ONLY reference)
- ❌ Deploy files from this directory (not production-ready)
- ❌ Trust AWS SCT output blindly (~30% requires manual correction)

## Workflow Integration

1. **Analysis Phase:** Read `sqlserver/` to understand original logic
2. **Baseline Phase:** Review `pgsql-aws-sct-converted/` for AWS SCT issues
3. **Correction Phase:** Create corrected version in `building/pgsql/refactored/`

## Key Differences

| Aspect | SQL Server Original | AWS SCT Converted |
|--------|---------------------|-------------------|
| **File Count** | 822 | 1,385 (+69%) |
| **Completeness** | 100% (original) | ~70% (requires fixes) |
| **Quality** | Production SQL Server | Baseline (P0-P3 issues) |
| **Organization** | 0-14 categories | 0-21 categories |

## Navigation

- See [sqlserver/README.md](sqlserver/README.md) for T-SQL originals
- See [pgsql-aws-sct-converted/README.md](pgsql-aws-sct-converted/README.md) for AWS SCT baseline

---

**Last Updated:** 2026-01-22
