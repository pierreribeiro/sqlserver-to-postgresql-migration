# Perseus PostgreSQL Database Design Documentation

This directory contains comprehensive database design documentation for the Perseus PostgreSQL migration.

## Files

### perseus-data-dictionary.md

**Comprehensive data dictionary** covering all 103 tables in the Perseus database.

**Contents:**
- Executive summary with key statistics
- Complete table of contents with anchor links
- P0 critical tables with full specifications (goo, goo_type, fatsmurf, container, material_transition, transition_material, m_upstream, m_downstream)
- Detailed documentation for key tables with:
  - Column specifications (name, type, nullable, default, description)
  - All constraints (PK, FK, UNIQUE, CHECK)
  - Index definitions with purposes
  - Relationship diagrams (parent/child tables)
  - Special notes and migration issues
- Comprehensive appendices:
  - Constraint summary (271 constraints)
  - Index summary (36 indexes)
  - Data type mappings (SQL Server → PostgreSQL)
  - Nested set model patterns

**Statistics:**
- **Length**: 1,166 lines / 43 KB
- **Tables Documented**: 103 (15+ with full detail, 88 in summary)
- **P0 Critical Tables**: 8 (fully documented)
- **Constraints**: 271 (94 PK + 124 FK + 40 UNIQUE + 12 CHECK)
- **Indexes**: 36 (P0 critical indexes highlighted)

## Quick Reference

### P0 Critical Tables

These 8 tables form the core material lineage tracking system:

| Table | Tier | Purpose | Special Notes |
|-------|------|---------|---------------|
| **goo** | 5 | Materials/samples | UID-based FK target, CASCADE delete |
| **goo_type** | 0 | Material type hierarchy | Nested set model, check constraint |
| **fatsmurf** | 4 | Experimental runs | UID-based FK target, CASCADE delete |
| **container** | 1 | Physical locations | Nested set model, SET NULL on delete |
| **material_transition** | 6 | Material → Experiment edges | Composite PK, VARCHAR FKs, CASCADE both |
| **transition_material** | 6 | Experiment → Material edges | Composite PK, VARCHAR FKs, CASCADE both |
| **m_upstream** | 0 | Cached upstream lineage | Denormalized cache, no FKs |
| **m_downstream** | 0 | Cached downstream lineage | Denormalized cache, no FKs |

### Migration Issues Resolved

1. **Duplicate FK**: perseus_user had 3 duplicate FKs to manufacturer → consolidated to 1
2. **Duplicate Index**: fatsmurf had 2 indexes on smurf_id → merged into 1
3. **IDENTITY Seeds**: m_number starts at 900000 (fixed from incorrect initial value)

### Constraint Highlights

- **CASCADE DELETE**: 40 FK constraints (audit trails, junction tables, **material lineage**)
- **SET NULL**: 4 FK constraints (container, workflow_step)
- **CASCADE UPDATE**: 2 FK constraints (material_transition, transition_material - **ONLY tables with this**)
- **Composite PKs**: 3 tables (material_transition, transition_material, material_inventory_threshold_notify_user)
- **Check Constraints**: 12 (enum-like, positive values, hierarchy, dates)

### Index Highlights

- **P0 Critical**: 4 indexes (uq_goo_uid, uq_fatsmurf_uid, idx_material_transition_transition_id, idx_transition_material_material_id)
- **Covering Indexes**: 4 (INCLUDE clause for index-only scans)
- **FILLFACTOR**: 9 indexes use FILLFACTOR=70-100 for performance tuning

## Usage

### For Database Administrators

- **Deployment Order**: Follow tier-based order (0→7) for table creation
- **Constraint Dependencies**: PK → FK → UNIQUE → CHECK → Indexes
- **Foreign Key Validation**: Ensure goo.uid and fatsmurf.uid UNIQUE indexes exist before material_transition/transition_material FKs

### For Developers

- **Schema Reference**: Complete column specs for all 103 tables
- **Relationship Mapping**: Parent/child relationships for JOIN queries
- **Constraint Awareness**: Understand CASCADE behaviors for delete operations
- **Nested Set Queries**: Efficient hierarchy queries for goo_type and container

### For Query Optimization

- **Index Usage**: 36 indexes documented with purposes
- **Covering Indexes**: 4 indexes with INCLUDE columns for index-only scans
- **Nested Set Model**: Avoid recursive CTEs for hierarchy queries

## Related Documentation

- **Table DDL**: `/source/building/pgsql/refactored/14. create-table/*.sql`
- **Constraints**: `/source/building/pgsql/refactored/17. create-constraint/*.sql`
- **Indexes**: `/source/building/pgsql/refactored/16. create-index/00-all-sqlserver-indexes-master.sql`
- **Dependency Graph**: `/docs/code-analysis/table-dependency-graph.md`

## Maintenance

### When to Update

Update the data dictionary when:

1. **Schema Changes**:
   - New tables added
   - Columns added/modified/removed
   - Data types changed

2. **Constraint Changes**:
   - New FK/PK/UNIQUE/CHECK constraints
   - CASCADE behavior modifications
   - Constraint drops

3. **Index Changes**:
   - New indexes created
   - Covering indexes (INCLUDE columns) added
   - Performance tuning (FILLFACTOR adjustments)

4. **Migration Issues**:
   - New issues discovered
   - Resolutions documented

### Update Process

1. Modify affected table sections in `perseus-data-dictionary.md`
2. Update statistics in Document Control and Executive Summary
3. Add notes to Appendices if needed
4. Update this README if major changes
5. Update version number and date

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-11 | Claude + Pierre Ribeiro | Initial comprehensive data dictionary |

---

**Questions or Issues?**

Contact: Pierre Ribeiro (Senior DBA/DBRE)
Project: Perseus Database Migration (SQL Server → PostgreSQL 17+)
