# Risk Register: Perseus Database Migration (SQL Server to PostgreSQL)

**Project:** Perseus Database Migration
**Created:** 2026-01-23
**Owner:** Pierre Ribeiro (Senior DBA/DBRE)
**Last Updated:** 2026-01-23

---

## Risk Assessment Methodology

**Probability Scale:** 1=Rare (<10%), 2=Unlikely (10-30%), 3=Possible (30-50%), 4=Likely (50-70%), 5=Almost Certain (>70%)
**Impact Scale:** 1=Negligible, 2=Minor, 3=Moderate, 4=Major, 5=Severe
**Risk Score:** Probability × Impact (1-25)
**Priority:** P0 (20-25), P1 (12-19), P2 (6-11), P3 (1-5)

---

## Active Risks

| ID | Risk Description | Probability | Impact | Score | Priority | Mitigation Strategy | Owner | Status |
|----|------------------|-------------|--------|-------|----------|---------------------|-------|--------|
| R001 | **Cutover overrun (>8 hours)** - Migration takes longer than 8-hour downtime window | 3 | 5 | 15 | P1 | Pre-test full cutover in staging, automate deployment, define go/no-go at hour 6 | Pierre | Active |
| R002 | **Data loss during migration** - Row count mismatch or checksum validation failure | 2 | 5 | 10 | P2 | Row-by-row MD5/SHA256 validation, automated rollback on failure, maintain SQL Server for 7 days | Pierre | Active |
| R003 | **Performance degradation >20%** - Critical queries exceed acceptable performance threshold | 3 | 4 | 12 | P1 | EXPLAIN ANALYZE all P0 queries, pre-optimize indexes, warm cache before validation | Pierre | Active |
| R004 | **FDW connection failures** - postgres_fdw cannot connect to hermes/sqlapps/deimeter | 2 | 4 | 8 | P2 | Pre-migration connectivity test in staging, 3× retry with exponential backoff, monitor latency | Pierre | Active |
| R005 | **Replication lag >5 min (p95)** - SymmetricDS replication to sqlwarehouse2 exceeds SLA | 3 | 3 | 9 | P2 | Test replication with production data volume, configure alerts (2/5/10 min), monitor backlog | Pierre | Active |
| R006 | **Recursive CTE infinite loop** - upstream/downstream views enter infinite recursion | 2 | 4 | 8 | P2 | Add recursion depth limits, test with malformed data, validate base case termination | Pierre | Active |
| R007 | **Materialized view refresh blocking** - translated view refresh blocks queries | 3 | 3 | 9 | P2 | Implement REFRESH CONCURRENTLY with UNIQUE index, test refresh under load, schedule off-peak | Pierre | Active |
| R008 | **Constraint violation post-migration** - PostgreSQL rejects data that SQL Server accepted | 2 | 4 | 8 | P2 | Validate constraints in staging, test with edge case data, document semantic differences | Pierre | Active |
| R009 | **Naming collision (case sensitivity)** - PostgreSQL folds unquoted names to lowercase | 2 | 3 | 6 | P2 | Use snake_case consistently, avoid quoted identifiers, validate naming convention compliance | Pierre | Active |
| R010 | **Dependency resolution failure** - Circular dependencies prevent deployment order | 2 | 4 | 8 | P2 | Use dependency analysis files (lote1-4), test deployment order in DEV, allow forward references | Pierre | Active |
| R011 | **AWS SCT baseline quality <70%** - Conversion tool produces more errors than expected | 3 | 3 | 9 | P2 | Manual review of all objects, quality score ALL objects ≥7.0/10, accept 30% manual effort | Pierre | Active |
| R012 | **Floating-point precision loss** - NUMERIC/DECIMAL conversions lose precision | 2 | 3 | 6 | P2 | Define 1e-10 tolerance, validate edge cases, document acceptable precision loss | Pierre | Active |
| R013 | **Timezone handling mismatch** - DATETIME/TIMESTAMP conversions introduce TZ errors | 2 | 3 | 6 | P2 | Use TIMESTAMP WITH TIME ZONE, validate timestamp comparisons, test DST boundaries | Pierre | Active |
| R014 | **GooList UDT pattern failure** - Temp table pattern doesn't match TVP behavior | 2 | 4 | 8 | P2 | Test mcgetupstreambylist/mcgetdownstreambylist with production data, validate temp table cleanup | Pierre | Active |
| R015 | **SQL Agent job migration gaps** - pgAgent/cron doesn't support all SQL Agent features | 3 | 3 | 9 | P2 | Map all 7 jobs to pg_cron, test scheduling, implement error logging, validate alerting | Pierre | Active |
| R016 | **Rollback failure** - Cannot roll back to SQL Server after cutover | 2 | 5 | 10 | P2 | Test rollback procedures in staging, maintain SQL Server for 7 days, document rollback steps | Pierre | Active |
| R017 | **Constitution compliance failure** - Objects don't pass 7 core principles validation | 3 | 3 | 9 | P2 | Automated linting for schema qualification, manual spot-check 10%, block PROD on P0 failures | Pierre | Active |
| R018 | **Test coverage insufficient (<90%)** - Missing edge case tests allow bugs to production | 3 | 3 | 9 | P2 | Enforce tiered coverage (100% P0, 90% P1, 80% P2/P3), generate tests from templates | Pierre | Active |
| R019 | **Empty table edge case** - Migration fails or produces errors on empty tables | 2 | 2 | 4 | P3 | Test with empty goo/material_transition, validate NULL handling, document expected behavior | Pierre | Active |
| R020 | **Max-row table performance** - Large table migration exceeds cutover window | 2 | 3 | 6 | P2 | Pre-load data before cutover, use parallel workers, validate data transfer rate | Pierre | Active |

---

## Mitigated/Closed Risks

| ID | Risk Description | Mitigation Outcome | Date Closed | Owner |
|----|------------------|-------------------|-------------|-------|
| R101 | **Stored procedure migration failure** - 15 procedures cannot be migrated | ✅ ALL 15 procedures migrated successfully in Sprint 3 (avg quality 8.67/10, +63-97% perf) | 2025-12-30 | Pierre |
| R102 | **WHILE loop conversion** - Procedural loops cannot be converted to set-based | ✅ ProcessDirtyTrees migrated using set-based coordinator pattern, LinkUnlinkedMaterials achieved 10-100× speedup | 2025-11-29 | Pierre |
| R103 | **OPENQUERY/linked server incompatibility** - External queries cannot use postgres_fdw | ✅ usp_UpdateContainerTypeFromArgus migrated with postgres_fdw, mock testing successful | 2025-11-29 | Pierre |

---

## Risk Trends

**Sprint 3 Retrospective (2025-12-30):**
- ✅ **3 risks closed** (R101-R103) - All stored procedures migrated successfully
- 🟡 **20 active risks remain** (R001-R020)
- 📊 **Risk velocity:** 15/15 procedures completed with zero P0/P1 incidents
- 🎯 **Key learnings:** Set-based patterns, pattern reuse, automated testing reduce risk

**Current Risk Distribution:**
- P0: 0 risks
- P1: 3 risks (R001, R003, R016)
- P2: 15 risks (R002, R004-R015, R017-R018, R020)
- P3: 2 risks (R019, R021)

**Top 3 Risks (by score):**
1. **R001** - Cutover overrun (15) - Define hour 6 checkpoint, pre-test staging
2. **R003** - Performance degradation (12) - EXPLAIN ANALYZE all P0 queries
3. **R002** - Data loss (10) - Row-by-row hash validation, 7-day rollback

---

## Risk Monitoring Cadence

- **Daily:** Review active P1 risks during sprint
- **Weekly:** Update risk scores based on progress
- **Sprint End:** Close mitigated risks, add new risks discovered
- **Pre-Deployment:** Re-assess all P0/P1 risks before PROD cutover

---

## Escalation Criteria

**Immediate Escalation (within 1 hour):**
- Any P0 risk identified
- Any risk score increases by 10+ points
- Any P1 risk blocking sprint delivery

**Weekly Escalation (sprint review):**
- 3+ P1 risks remain unmitigated for 2+ sprints
- Risk trend shows increasing scores
- New risks discovered during implementation

**Escalation Path:**
- Pierre Ribeiro (DBA) → Engineering Manager → VP Engineering

---

## Notes

- Risk register updated daily during active sprints
- Archived risks moved to tracking/risk-register-archive-YYYY-MM.md quarterly
- Risk IDs R001-R099: Active risks, R100+: Closed risks
- All risks linked to specific tasks in tasks.md for traceability

---

**Last Review:** 2026-01-23 | **Next Review:** Daily during Sprint 9
