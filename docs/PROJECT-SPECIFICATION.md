# Project Specification - Perseus Database Migration
## SQL Server to PostgreSQL 17 Migration

**Document Type:** Project Specification (Binding Reference)
**Project Owner:** Pierre Ribeiro (Senior DBA/DBRE + Data Engineer)
**Created:** 2026-01-18
**Version:** 1.0
**Status:** ACTIVE

---

## 1. Executive Summary

### 1.1 Mission Statement

Systematically migrate the Perseus database from SQL Server 2014 to PostgreSQL 17, ensuring:
- Zero production incidents during cutover
- Minimal downtime (target: <8 hours)
- Performance within 20% of SQL Server baseline
- Complete data integrity preservation
- Full documentation and operational runbooks

### 1.2 Project Scope

| Scope Item | In Scope | Out of Scope |
|------------|----------|--------------|
| Database Objects | Tables, Views, Functions, Procedures, Types, Indexes, Constraints | Application code changes |
| Integrations | FDW setup for hermes, sqlapps, deimeter | Application API changes |
| Replication | SymmetricDS configuration for sqlwarehouse2 | New replication topology design |
| Testing | Unit, Integration, Performance testing | End-user acceptance testing |
| Documentation | Technical docs, Runbooks, Training | User manuals |

### 1.3 Key Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Functional Correctness** | 100% | SQL Server vs PostgreSQL output diff |
| **Performance** | Within 20% of baseline | Query execution time comparison |
| **Data Integrity** | Zero data loss | Row counts + checksum validation |
| **Availability** | 99.9% post-migration | Uptime monitoring |
| **Test Coverage** | >90% | Unit + integration tests |
| **Quality Score** | ≥8.0/10 | 5-dimension scoring methodology |

---

## 2. Current State (As-Is)

### 2.1 Infrastructure Context

| Component | Details |
|-----------|---------|
| **Source System** | SQL Server 2014 Enterprise |
| **Instance** | sqlappsta (Cluster MSSQL Server) |
| **Database** | Perseus |
| **Application** | Pegasus (Material tracking system) |
| **Business Domain** | Sample tracking, processes, media, raw material recipes |

### 2.2 Object Inventory (Production)

| Object Type | Count | Status |
|-------------|-------|--------|
| **Tables** | 91 | Pending migration |
| **Indexes** | 352 | Pending migration |
| **Constraints** | 271 | Pending migration |
| **Views** | 22 | Analyzed (Lote 3) |
| **Stored Procedures** | 21 | 15 Corrected, 6 MS Replication |
| **SQL Table Valued Functions** | 15 | Analyzed (Lote 2) |
| **SQL Scalar Functions** | 10 | Analyzed (Lote 2) |
| **User-Defined Types** | 1 | Analyzed (Lote 4) - GooList |
| **Jobs (SQL Agent)** | 7 | Pending refactoring |

### 2.3 External Dependencies & Integrations

#### 2.3.1 Incoming Data (FDW Required)

| Source Database | Tables | Access Method |
|-----------------|--------|---------------|
| hermes | 6 tables | FDW (postgres_fdw) |
| sqlapps.common | 9 tables | FDW (postgres_fdw) |
| deimeter | 2 tables | FDW (postgres_fdw) |

#### 2.3.2 Outgoing Data (Replication)

| Target | Method | Tool |
|--------|--------|------|
| sqlwarehouse2 | Replication | SymmetricDS |

---

## 3. Target State (To-Be)

### 3.1 Target Infrastructure

| Component | Details |
|-----------|---------|
| **Target System** | PostgreSQL 17 |
| **Cluster** | AWS RDS or EC2 (TBD) |
| **Database** | perseus |
| **High Availability** | Multi-AZ deployment |
| **Backup Strategy** | Daily snapshots + WAL archiving |

### 3.2 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                             │
│                    Pegasus (Material Tracking)                       │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      PostgreSQL 17 Cluster                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    DATABASE: perseus                           │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │  │
│  │  │   Tables    │ │   Views     │ │  Functions  │             │  │
│  │  │    (91)     │ │    (22)     │ │    (25)     │             │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │  │
│  │  │ Procedures  │ │  Mat Views  │ │   Indexes   │             │  │
│  │  │    (21)     │ │    (1+)     │ │   (352)     │             │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              FOREIGN DATA WRAPPERS (postgres_fdw)              │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │  │
│  │  │   hermes    │ │   sqlapps   │ │  deimeter   │             │  │
│  │  │  (6 tables) │ │  (9 tables) │ │  (2 tables) │             │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    REPLICATION (SymmetricDS)                         │
│                    Target: sqlwarehouse2                             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Complete Object Inventory

### 4.1 Stored Procedures (21 Total)

#### 4.1.1 Core Material Processing (11 Procedures)

| # | Procedure Name | Priority | Status | Quality Score | Sprint |
|---|----------------|----------|--------|---------------|--------|
| 1 | ReconcileMUpstream | P0 | CORRECTED | 8.2/10 | Sprint 2 |
| 2 | AddArc | P0 | CORRECTED | 8.5/10 | Sprint 3 |
| 3 | RemoveArc | P0 | CORRECTED | 9.0/10 | Sprint 3 |
| 4 | ProcessSomeMUpstream | P1 | CORRECTED | 8.0/10 | Sprint 2 |
| 5 | ProcessDirtyTrees | P1 | CORRECTED | 8.5/10 | Sprint 3 |
| 6 | MoveContainer | P1 | CORRECTED | 9.0/10 | Sprint 8 |
| 7 | MoveGooType | P2 | CORRECTED | 8.7/10 | Sprint 8 |
| 8 | GetMaterialByRunProperties | P1 | CORRECTED | 8.8/10 | Sprint 4 |
| 9 | LinkUnlinkedMaterials | P2 | CORRECTED | 9.6/10 | Sprint 8 |
| 10 | MaterialToTransition | P2 | CORRECTED | 9.5/10 | Sprint 6 |
| 11 | TransitionToMaterial | P2 | CORRECTED | 9.5/10 | Sprint 5 |

#### 4.1.2 Utility & Update Procedures (4 Procedures)

| # | Procedure Name | Priority | Status | Quality Score | Sprint |
|---|----------------|----------|--------|---------------|--------|
| 12 | sp_move_node | P2 | CORRECTED | 8.5/10 | Sprint 5 |
| 13 | usp_UpdateContainerTypeFromArgus | P2 | CORRECTED | 8.6/10 | Sprint 7 |
| 14 | usp_UpdateMDownstream | P1 | CORRECTED | 8.5/10 | Sprint 2 |
| 15 | usp_UpdateMUpstream | P1 | CORRECTED | 8.5/10 | Sprint 1 |

#### 4.1.3 MS SQL Server Replication Procedures (6 Procedures)

| # | Procedure Name | Priority | Status | Notes |
|---|----------------|----------|--------|-------|
| 16 | sp_MSdel_dbobarcodes | P3 | REVIEW | May not be needed |
| 17 | sp_MSins_dbobarcodes | P3 | REVIEW | May not be needed |
| 18 | sp_MSupd_dbobarcodes | P3 | REVIEW | May not be needed |
| 19 | sp_MSdel_dboseed_vials | P3 | REVIEW | May not be needed |
| 20 | sp_MSins_dboseed_vials | P3 | REVIEW | May not be needed |
| 21 | sp_MSupd_dboseed_vials | P3 | REVIEW | May not be needed |

### 4.2 Functions (24 Total)

#### 4.2.1 McGet* Family - CRITICAL (4 Functions)

| # | Function Name | Priority | Type | Complexity |
|---|---------------|----------|------|------------|
| 1 | McGetUpStream | P0 | Table-Valued | 8/10 |
| 2 | McGetDownStream | P0 | Table-Valued | 8/10 |
| 3 | McGetUpStreamByList | P0 | Table-Valued | 9/10 |
| 4 | McGetDownStreamByList | P1 | Table-Valued | 8/10 |

#### 4.2.2 Get* Family - Legacy (12 Functions)

| # | Function Name | Priority | Type | Complexity |
|---|---------------|----------|------|------------|
| 5 | GetUpStream | P1 | Table-Valued | 7/10 |
| 6 | GetDownStream | P1 | Table-Valued | 7/10 |
| 7 | GetUpStreamFamily | P1 | Table-Valued | 6/10 |
| 8 | GetDownStreamFamily | P1 | Table-Valued | 6/10 |
| 9 | GetUpStreamContainers | P1 | Table-Valued | 6/10 |
| 10 | GetDownStreamContainers | P1 | Table-Valued | 6/10 |
| 11 | GetUnProcessedUpStream | P2 | Table-Valued | 5/10 |
| 12 | GetUpstreamMasses | P2 | Table-Valued | 9/10 |
| 13 | GetReadCombos | P2 | Table-Valued | 7/10 |
| 14 | GetTransferCombos | P2 | Table-Valued | 7/10 |
| 15 | GetSampleTime | P2 | Table-Valued | 8/10 |
| 16 | GetFermentationFatSmurf | P2 | Table-Valued | 5/10 |

#### 4.2.3 Utility Functions (8 Functions)

| # | Function Name | Priority | Type | Complexity |
|---|---------------|----------|------|------------|
| 17 | McGetUpDownStream | P2 | Table-Valued | 4/10 |
| 18 | GetExperiment | P3 | Scalar | 3/10 |
| 19 | GetHermesExperiment | P3 | Scalar | 3/10 |
| 20 | GetHermesRun | P3 | Scalar | 3/10 |
| 21 | GetHermesUid | P3 | Scalar | 3/10 |
| 22 | ReversePath | P3 | Scalar | 3/10 |
| 23 | RoundDateTime | P3 | Scalar | 2/10 |
| 24 | initCaps | P3 | Scalar | 3/10 |

### 4.3 Views (22 Total)

#### 4.3.1 Critical Views (4 Views)

| # | View Name | Priority | Type | Dependencies |
|---|-----------|----------|------|--------------|
| 1 | translated | P0 | INDEXED (Materialized) | material_transition, transition_material |
| 2 | upstream | P1 | Recursive CTE | translated |
| 3 | downstream | P1 | Recursive CTE | translated |
| 4 | goo_relationship | P1 | UNION | goo, fatsmurf, hermes.run |

#### 4.3.2 Business Logic Views (11 Views)

| # | View Name | Priority | Type |
|---|-----------|----------|------|
| 5 | vw_lot | P2 | JOIN |
| 6 | vw_lot_edge | P2 | JOIN |
| 7 | vw_lot_path | P2 | Recursive CTE |
| 8 | vw_material_transition_material_up | P2 | JOIN |
| 9 | vw_fermentation_upstream | P2 | JOIN |
| 10 | vw_process_upstream | P2 | JOIN |
| 11 | vw_processable_logs | P2 | JOIN |
| 12 | vw_recipe_prep | P2 | JOIN |
| 13 | vw_recipe_prep_part | P2 | JOIN |
| 14 | vw_jeremy_runs | P3 | JOIN (Deprecation candidate) |
| 15 | vw_tom_perseus_sample_prep_materials | P3 | JOIN (Deprecation candidate) |

#### 4.3.3 Combined/Integration Views (7 Views)

| # | View Name | Priority | Type |
|---|-----------|----------|------|
| 16 | hermes_run | P2 | Cross-schema |
| 17 | material_transition_material | P2 | JOIN |
| 18 | combined_field_map | P3 | UNION |
| 19 | combined_field_map_block | P3 | UNION |
| 20 | combined_field_map_display_type | P3 | UNION |
| 21 | combined_sp_field_map | P3 | UNION |
| 22 | combined_sp_field_map_display_type | P3 | UNION |

### 4.4 User-Defined Types (1 Total)

| # | Type Name | Priority | Structure | Used By |
|---|-----------|----------|-----------|---------|
| 1 | GooList | P0 | TVP (uid NVARCHAR(50) PK) | McGetUpStreamByList, McGetDownStreamByList, ReconcileMUpstream, ProcessSomeMUpstream |

### 4.5 Tables (91 Total)

#### 4.5.1 Critical Tables (Core Business)

| Table | Priority | Row Count (Est.) | Dependencies |
|-------|----------|------------------|--------------|
| goo | P0 | High | Material master |
| material_transition | P0 | High | Parent→Transition edges |
| transition_material | P0 | High | Transition→Child edges |
| m_upstream | P0 | High | Cached upstream graph |
| m_downstream | P0 | High | Cached downstream graph |
| m_upstream_dirty_leaves | P0 | Medium | Reconciliation queue |
| container | P1 | Medium | Inventory management |
| fatsmurf | P1 | Medium | Process/experiment |
| goo_type | P2 | Low | Material types |

*(Full table inventory to be completed during Sprint 9)*

---

## 5. Dependency Analysis Summary

### 5.1 Critical Path (P0 Objects)

The following objects form the critical migration path and MUST be completed in strict sequence:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CRITICAL PATH SEQUENCE                           │
└─────────────────────────────────────────────────────────────────────┘

Step 1: MATERIALIZED VIEW
└─> translated (INDEXED VIEW → MATERIALIZED VIEW)
    └─> Dependencies: material_transition, transition_material

Step 2: USER-DEFINED TYPE
└─> GooList (TVP → TEMPORARY TABLE pattern)
    └─> Dependencies: None (foundational)

Step 3: FUNCTIONS (4 P0 Functions)
└─> McGetUpStream()
└─> McGetDownStream()
└─> McGetUpStreamByList()
└─> McGetDownStreamByList()
    └─> Dependencies: translated view, GooList type

Step 4: STORED PROCEDURES (3 P0 Procedures)
└─> AddArc
└─> RemoveArc
└─> ReconcileMUpstream
    └─> Dependencies: McGet* functions
```

### 5.2 Cross-Object Dependencies

| From Object | To Object | Dependency Type |
|-------------|-----------|-----------------|
| AddArc, RemoveArc | McGetUpStream, McGetDownStream | Function Call |
| ReconcileMUpstream | McGetUpStreamByList | Function Call |
| ProcessSomeMUpstream | McGetUpStreamByList | Function Call |
| McGet* Functions | translated | View Query |
| McGet*ByList Functions | GooList | Parameter Type |
| translated | material_transition, transition_material | Table Join |
| goo_relationship | goo, fatsmurf, hermes.run | Table UNION |
| upstream, downstream | translated | View Reference |

### 5.3 External Dependencies

| Object | External System | Migration Strategy |
|--------|-----------------|-------------------|
| goo_relationship | hermes.run | FDW (postgres_fdw) |
| hermes_run | hermes.run | FDW (postgres_fdw) |
| Get*Hermes* Functions | hermes schema | FDW (postgres_fdw) |
| usp_UpdateContainerTypeFromArgus | Argus (Linked Server) | FDW or API |

---

## 6. Migration Strategy

### 6.1 Approach

| Strategy | Description |
|----------|-------------|
| **Tool** | AWS Schema Conversion Tool (SCT) as baseline |
| **Review** | Manual review and correction of all converted code |
| **Quality** | 5-dimension quality scoring (≥8.0/10 required) |
| **Testing** | Unit, Integration, Performance testing phases |
| **Deployment** | Staged rollout: DEV → STAGING → PRODUCTION |

### 6.2 Conversion Strategy by Object Type

| Object Type | Strategy |
|-------------|----------|
| **Tables** | AWS SCT + Index optimization review |
| **Views** | AWS SCT + MATERIALIZED VIEW for indexed views |
| **Functions** | AWS SCT + Manual T-SQL to PL/pgSQL conversion |
| **Procedures** | AWS SCT + Manual correction (5-phase workflow) |
| **Types (TVP)** | TEMPORARY TABLE pattern (no PostgreSQL equivalent) |
| **Linked Servers** | postgres_fdw (Foreign Data Wrapper) |

### 6.3 GooList Type Conversion Strategy

**Recommended Approach:** TEMPORARY TABLE Pattern

```sql
-- PostgreSQL Implementation
CREATE TEMP TABLE tmp_goolist (
    uid VARCHAR(50) NOT NULL PRIMARY KEY
) ON COMMIT DROP;

-- Function receives table name as parameter
CREATE FUNCTION mcget_upstream_by_list(p_temp_table_name TEXT)
RETURNS TABLE (...) AS $$
BEGIN
    RETURN QUERY EXECUTE format('
        WITH RECURSIVE upstream AS (...)
        SELECT ... FROM %I ...
    ', p_temp_table_name);
END;
$$ LANGUAGE plpgsql;
```

---

## 7. Execution Roadmap

### 7.1 Phase Summary

| Phase | Sprint | Duration | Focus |
|-------|--------|----------|-------|
| **Phase 1** | 0-8 | 8 weeks | Procedure Conversion (COMPLETE) |
| **Phase 2** | 9 | 1 week | Integration & Staging |
| **Phase 3** | 10-11 | 2-3 weeks | Functions & Views Migration |
| **Phase 4** | 12-14 | 3-4 weeks | Tables, Indexes, Constraints |
| **Phase 5** | 15-16 | 2 weeks | FDW & Replication Setup |
| **Phase 6** | 17 | 1 week | Final Validation & Cutover |

### 7.2 Current Status

| Milestone | Status | Completion |
|-----------|--------|------------|
| Sprint 0: Setup & Planning | COMPLETE | 100% |
| Sprints 1-8: Procedure Conversion | COMPLETE | 15/15 (100%) |
| Sprint 9: Integration & Staging | READY TO START | 0% |
| Sprints 10-16: Remaining Objects | PENDING | 0% |
| Sprint 17: Production Deployment | PENDING | 0% |

### 7.3 Sprint 9 Objectives (Current)

**Goal:** Deploy all 15 procedures to STAGING and validate production-readiness

**Tasks:**
1. STAGING environment verification
2. Deploy all 15 corrected procedures
3. Set up monitoring dashboards
4. Execute unit tests (>95% pass rate)
5. Execute integration tests (>90% pass rate)
6. Performance benchmarking
7. Security review
8. Documentation review
9. Rollback procedure validation

---

## 8. Quality Standards

### 8.1 Quality Scoring Methodology

All converted objects are scored across 5 dimensions:

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **Syntax Correctness** | 20% | Valid PostgreSQL 17 syntax |
| **Logic Preservation** | 30% | Business logic identical to original |
| **Performance** | 20% | Within 20% of SQL Server baseline |
| **Maintainability** | 15% | Readable, documented, follows Constitution |
| **Security** | 15% | No injection risks, proper permissions |

**Passing Threshold:**
- Overall score: ≥7.0/10
- No individual dimension: <6.0/10

### 8.2 Issue Classification

| Priority | Description | Action | SLA |
|----------|-------------|--------|-----|
| **P0** | Blocks execution, data corruption risk | Immediate fix | Before any testing |
| **P1** | Logic errors, performance >50% degradation | Fix before deployment | Within sprint |
| **P2** | Non-critical improvements | Fix in next sprint | Next sprint |
| **P3** | Style/convention suggestions | Track for future | Backlog |

### 8.3 Current Quality Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Procedures Converted | 15 | 15 (100%) |
| Average Quality Score | ≥8.0/10 | 8.71/10 |
| Time Efficiency | 100% | 37% budget used |
| P0 Issues Resolved | 100% | 100% |

---

## 9. Risk Management

### 9.1 Critical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **VIEW translated performance** | CRITICAL | MEDIUM | MATERIALIZED VIEW + trigger refresh + production-scale testing |
| **GooList conversion strategy** | CRITICAL | MEDIUM | Prototype all 3 options, benchmark with real batch sizes |
| **Recursive CTE performance** | HIGH | MEDIUM | work_mem tuning, consider materialized views |
| **Data loss in lineage** | CRITICAL | LOW | Comprehensive testing, SQL Server vs PostgreSQL diff |

### 9.2 High Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **hermes schema unavailable** | MEDIUM | MEDIUM | Coordinate migration timing |
| **Linked server (Argus) integration** | MEDIUM | HIGH | Early FDW testing, fallback to API |
| **Cursor refactoring (GetUpstreamMasses)** | MEDIUM | HIGH | Set-based refactoring + testing |
| **Timeline overrun** | MEDIUM | MEDIUM | Buffer week, prioritize P0/P1 only |

---

## 10. Documentation & References

### 10.1 Related Documents

| Document | Location | Purpose |
|----------|----------|---------|
| PostgreSQL Programming Constitution | docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md | Coding standards |
| Dependency Analysis - Consolidated | docs/code-analysis/dependency-analysis-consolidated.md | Object dependencies |
| Dependency Analysis - Lote 1 (SPs) | docs/code-analysis/dependency-analysis-lote1-stored-procedures.md | Procedure analysis |
| Dependency Analysis - Lote 2 (Functions) | docs/code-analysis/dependency-analysis-lote2-functions.md | Function analysis |
| Dependency Analysis - Lote 3 (Views) | docs/code-analysis/dependency-analysis-lote3-views.md | View analysis |
| Dependency Analysis - Lote 4 (Types) | docs/code-analysis/dependency-analysis-lote4-types.md | Type analysis |
| Progress Tracker | tracking/progress-tracker.md | Sprint status |
| Priority Matrix | tracking/priority-matrix.csv | Object prioritization |
| Template - Project Plan | legacy/docs/TODO/Template-Project-Plan.md | Project template |

### 10.2 Repository Structure

```
sqlserver-to-postgresql-migration/
├── docs/
│   ├── code-analysis/
│   │   ├── procedures/           # Individual procedure analyses
│   │   ├── dependency-analysis-*.md  # Dependency documents
│   ├── PROJECT-SPECIFICATION.md  # This document
│   ├── POSTGRESQL-PROGRAMMING-CONSTITUTION.md
│   ├── Project-History.md
├── source/
│   ├── original/
│   │   ├── sqlserver/            # Original T-SQL code
│   │   └── pgsql-aws-sct-converted/  # AWS SCT output
│   ├── building/
│   │   └── pgsql/
│   │       └── refactored/       # Production-ready PostgreSQL code
├── tracking/
│   ├── progress-tracker.md       # Sprint tracking
│   ├── priority-matrix.csv       # Object priorities
├── tests/
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   └── performance/              # Performance benchmarks
├── scripts/
│   ├── validation/               # Validation scripts
│   └── deployment/               # Deployment scripts
```

---

## 11. Stakeholder Questions (Decision Required)

### 11.1 Immediate Decisions (Sprint 9)

| # | Question | Options | Decision By |
|---|----------|---------|-------------|
| 1 | GooList conversion strategy | TEMP TABLE (rec.) / ARRAY / JSONB | Sprint 9 Day 1 |
| 2 | `translated` view refresh strategy | Trigger-based (rec.) / Scheduled | Sprint 9 Day 1 |
| 3 | Acceptable performance degradation | 20% (rec.) / 10% / 50% | Sprint 9 Day 1 |

### 11.2 Future Decisions

| # | Question | Options | Decision By |
|---|----------|---------|-------------|
| 4 | RemoveArc commented logic | Restore / Keep commented | Sprint 11 |
| 5 | Deprecated views (user-specific) | Migrate / Deprecate | Sprint 14 |
| 6 | MS Replication procedures | Migrate / Deprecate | Sprint 12 |
| 7 | Cutover strategy | Big-bang / Blue-green / Staged | Sprint 15 |
| 8 | Production data for testing | Available? Size? | Sprint 9 |

---

## 12. Approval & Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Owner | Pierre Ribeiro | _________ | _________ |
| Technical Lead | _________ | _________ | _________ |
| DBA Team | _________ | _________ | _________ |
| Business Stakeholder | _________ | _________ | _________ |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Pierre Ribeiro + Claude | Initial release |

---

**End of Project Specification**
