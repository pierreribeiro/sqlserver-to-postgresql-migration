# Production-Ready PostgreSQL Objects (Refactored)

## Purpose

Production-ready PostgreSQL objects validated and corrected from AWS SCT baseline. All objects in this directory have passed quality gates (≥7.0/10 score) and are deployment-ready.

## Structure

Organized in **dependency order** (0-21 categories): drop operations first, create operations last.

```
refactored/
├── 0. drop-trigger/
├── 1. drop-function/
├── 2. drop-procedure/
├── 3. drop-foreign-key-constraint/
├── 4. drop-constraint/
├── 5. drop-index/
├── 6. drop-view/
├── 7. drop-table/
├── 8. drop-domain/
├── 9. drop-type/
├── 10. drop-database/
├── 11. create-database/
├── 12. create-type/
├── 13. create-domain/
├── 14. create-table/
├── 15. create-view/
├── 16. create-index/
├── 17. create-constraint/
├── 18. create-foreign-key-constraint/
├── 19. create-function/
├── 20. create-procedure/    # ✅ 15 procedures COMPLETE
└── 21. create-trigger/
```

## Contents

### Object Categories

| Category | Status | Files | Description |
|----------|--------|-------|-------------|
| **0. drop-trigger/** | Empty | 0 | Drop triggers first |
| **1. drop-function/** | Empty | 0 | Drop functions |
| **2. drop-procedure/** | Empty | 0 | Drop procedures |
| **3. drop-foreign-key-constraint/** | Empty | 0 | Drop FK constraints |
| **4. drop-constraint/** | Empty | 0 | Drop constraints |
| **5. drop-index/** | Empty | 0 | Drop indexes |
| **6. drop-view/** | Empty | 0 | Drop views |
| **7. drop-table/** | Empty | 0 | Drop tables |
| **8. drop-domain/** | Empty | 0 | Drop domains |
| **9. drop-type/** | Empty | 0 | Drop types |
| **10. drop-database/** | Empty | 0 | Drop database |
| **11. create-database/** | Empty | 0 | Create database |
| **12. create-type/** | Pending | 0 | Create types (GooList → temp table) |
| **13. create-domain/** | Empty | 0 | Create domains |
| **14. create-table/** | Pending | 0 | Create tables (91 pending) |
| **15. create-view/** | Pending | 0 | Create views (22 pending, 1 materialized) |
| **16. create-index/** | Pending | 0 | Create indexes (352 pending) |
| **17. create-constraint/** | Pending | 0 | Create constraints (271 pending) |
| **18. create-foreign-key-constraint/** | Pending | 0 | Create FK constraints |
| **19. create-function/** | Pending | 0 | Create functions (25 pending) |
| **20. create-procedure/** | ✅ **COMPLETE** | **15** | Create procedures (ALL complete) |
| **21. create-trigger/** | Pending | 0 | Create triggers |

### Completed Procedures (20. create-procedure/)

All **15 procedures** production-ready with avg quality score 8.67/10:

1. `perseus.addarc.sql` - Add arc to material transition graph
2. `perseus.getmaterialbyrunproperties.sql` - Retrieve materials by run properties
3. `perseus.linkunlinkedmaterials.sql` - Link unlinked materials in graph
4. `perseus.materialtotransition.sql` - Convert material to transition
5. `perseus.movecontainer.sql` - Move container between locations
6. `perseus.movegootype.sql` - Update goo type assignments
7. `perseus.processdirtytrees.sql` - Process dirty tree structures
8. `perseus.processsomemupstream.sql` - Process upstream material relationships
9. `perseus.reconcilemupstream.sql` - Reconcile upstream material data
10. `perseus.removearc.sql` - Remove arc from material transition graph
11. `perseus.sp_move_node.sql` - Move node in hierarchy
12. `perseus.transitiontomaterial.sql` - Convert transition to material
13. `perseus.usp_updatecontainertypefromargus.sql` - Update container type from Argus
14. `perseus.usp_updatemdownstream.sql` - Update downstream material relationships
15. `perseus.usp_updatemupstream.sql` - Update upstream material relationships

## Quality Standards

**ALL objects in this directory MUST meet:**
- ✅ Quality score ≥7.0/10 (target ≥8.0/10)
- ✅ Performance within ±20% of SQL Server baseline
- ✅ Zero P0/P1 issues (critical and high priority)
- ✅ All 7 core principles compliant
- ✅ Comprehensive unit tests passing
- ✅ Schema-qualified object references
- ✅ Proper error handling with specific exception types

## Workflow

Objects move through this directory following the 4-phase process:

### Phase 1: Analysis
- Read original T-SQL from `source/original/sqlserver/`
- Read AWS SCT output from `source/original/pgsql-aws-sct-converted/`
- Identify P0-P3 issues, calculate quality score

### Phase 2: Correction
- Start with AWS SCT baseline
- Fix ALL P0 issues (critical blockers)
- Fix ALL P1 issues (high priority)
- Add error handling, schema qualification
- Save to appropriate category directory here

### Phase 3: Validation
- Syntax validation (must pass)
- Dependency resolution (must pass)
- Unit tests (must pass)
- Performance benchmark (within ±20%)
- Data integrity validation (100% match)

### Phase 4: Deployment
- DEV → STAGING → PROD
- Smoke tests at each stage
- Rollback plan + monitoring + runbook

## Navigation

- Up: [../README.md](../README.md)
- See: [20. create-procedure/](20.%20create-procedure/) for completed procedures

---

**Last Updated:** 2026-01-22 | **Status:** 15/769 objects (2%) production-ready | **Next Phase:** P0 critical path (views, functions, tables)
