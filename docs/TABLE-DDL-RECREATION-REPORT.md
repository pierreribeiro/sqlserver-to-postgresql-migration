# Table DDL Recreation Report - Perseus Database Migration

## Executive Summary

**Migration Date:** 2026-02-10
**Analyst:** Claude (Database Expert Agent) + Pierre Ribeiro
**Source Database:** SQL Server 2019 (Perseus production)
**Target Database:** PostgreSQL 17+
**Migration Tool:** Python script with pyodbc + topological sort analysis

---

## Conversion Statistics

| Metric | Count | Status |
|--------|-------|--------|
| **Total Tables Converted** | 101 | SUCCESS |
| **DBO Schema Tables** | 93 | SUCCESS |
| **FDW Tables (hermes)** | 6 | SUCCESS |
| **FDW Tables (demeter)** | 2 | SUCCESS |
| **Conversion Errors** | 0 | PASS |
| **Column Count Verification** | 101/101 | PASS |
| **Foreign Key Constraints** | 124 | VERIFIED |
| **Known Issues** | 3 | DOCUMENTED |

---

## Schema Distribution

### DBO Schema (93 tables)

| Category | Count | Notes |
|----------|-------|-------|
| Main Tables | 91 | Core Perseus tables |
| Utility Tables | 1 | perseus_table_and_row_counts |
| Special Tables | 1 | permissions |
| **Total DBO** | **93** | |

### FDW Schemas (8 tables)

| Schema | Tables | Purpose |
|--------|--------|---------|
| hermes | 6 | Fermentation/experiment data via postgres_fdw |
| demeter | 2 | Seed vial tracking via postgres_fdw |
| **Total FDW** | **8** | |

---

## Column Count Verification

All 101 tables have been verified for column count match between SQL Server and PostgreSQL DDL.

### Sample Verification (Key Tables)

| Table Name | SQL Server Columns | PostgreSQL Columns | Status | Notes |
|------------|-------------------|-------------------|---------|-------|
| goo | 20 | 20 | PASS | P0 critical table |
| fatsmurf | 18 | 18 | PASS | P0 critical table, has computed column |
| material_transition | 3 | 3 | PASS | P0 critical table, UID-based FKs |
| transition_material | 2 | 2 | PASS | P0 critical table, UID-based FKs |
| perseus_user | 9 | 9 | PASS | Has duplicate FK issue |
| hermes.run | 90 | 90 | PASS | FDW table (corrected from 8) |
| demeter.seed_vials | 22 | 22 | PASS | FDW table (corrected from 11) |
| goo_type | 12 | 12 | PASS | P0 critical table |
| m_upstream | 4 | 4 | PASS | P0 critical table |
| m_downstream | 4 | 4 | PASS | P0 critical table |

### Complete DBO Tables Column Verification

| Table Name | Columns | Table Name | Columns | Table Name | Columns |
|------------|---------|------------|---------|------------|---------|
| alembic_version | 1 | cm_application | 8 | cm_application_group | 2 |
| cm_group | 5 | cm_project | 5 | cm_unit | 7 |
| cm_unit_compare | 2 | cm_unit_dimensions | 10 | cm_user | 7 |
| cm_user_group | 2 | coa | 3 | coa_spec | 9 |
| color | 1 | container | 13 | container_history | 3 |
| container_type | 7 | container_type_position | 6 | display_layout | 2 |
| display_type | 2 | external_goo_type | 4 | fatsmurf | 18 |
| fatsmurf_attachment | 8 | fatsmurf_comment | 5 | fatsmurf_history | 3 |
| fatsmurf_reading | 5 | feed_type | 10 | field_map | 14 |
| field_map_block | 3 | field_map_display_type | 6 | field_map_display_type_user | 3 |
| field_map_set | 6 | field_map_type | 2 | goo | 20 |
| goo_attachment | 9 | goo_attachment_type | 2 | goo_comment | 6 |
| goo_history | 3 | goo_process_queue_type | 2 | goo_type | 12 |
| goo_type_combine_component | 3 | goo_type_combine_target | 3 | history | 4 |
| history_type | 3 | history_value | 3 | m_downstream | 4 |
| m_number | 1 | m_upstream | 4 | m_upstream_dirty_leaves | 1 |
| manufacturer | 4 | material_inventory | 14 | material_inventory_threshold | 12 |
| material_inventory_threshold_notify_user | 2 | material_qc | 5 | material_transition | 3 |
| migration | 3 | permissions | 2 | perseus_table_and_row_counts | 3 |
| perseus_user | 9 | person | 8 | poll | 11 |
| poll_history | 3 | prefix_incrementor | 2 | property | 4 |
| property_option | 5 | recipe | 16 | recipe_part | 11 |
| recipe_project_assignment | 2 | robot_log | 14 | robot_log_container_sequence | 5 |
| robot_log_error | 3 | robot_log_read | 7 | robot_log_transfer | 11 |
| robot_log_type | 4 | robot_run | 5 | s_number | 1 |
| saved_search | 8 | scraper | 19 | sequence_type | 2 |
| smurf | 6 | smurf_goo_type | 4 | smurf_group | 4 |
| smurf_group_member | 3 | smurf_property | 6 | submission | 4 |
| submission_entry | 9 | tmp_messy_links | 5 | transition_material | 2 |
| unit | 6 | workflow | 8 | workflow_attachment | 7 |
| workflow_section | 4 | workflow_step | 17 | workflow_step_type | 2 |

### FDW Tables Column Verification

| Schema | Table Name | Columns | Status | Notes |
|--------|------------|---------|--------|-------|
| hermes | run | 90 | PASS | Corrected from 8 columns |
| hermes | run_condition | 4 | PASS | |
| hermes | run_condition_option | 4 | PASS | |
| hermes | run_condition_value | 5 | PASS | |
| hermes | run_master_condition | 10 | PASS | |
| hermes | run_master_condition_type | 3 | PASS | |
| demeter | barcodes | 3 | PASS | |
| demeter | seed_vials | 22 | PASS | Corrected from 11 columns |

---

## Data Type Mapping Summary

### T-SQL to PostgreSQL Data Type Conversions

| SQL Server Type | PostgreSQL Type | Count | Notes |
|-----------------|----------------|-------|-------|
| **int** | INTEGER | ~450 | Standard integer |
| **bigint** | BIGINT | ~25 | Large integers |
| **nvarchar(n)** | VARCHAR(n) | ~350 | Unicode strings (no N' prefix in PG) |
| **nvarchar(MAX)** | TEXT | ~50 | Large text fields |
| **datetime** | TIMESTAMP(3) | ~180 | SQL Server datetime precision |
| **bit** | BOOLEAN | ~75 | Boolean flags |
| **decimal(p,s)** | NUMERIC(p,s) | ~30 | Exact numeric |
| **float** | DOUBLE PRECISION | ~20 | Approximate numeric |
| **uniqueidentifier** | UUID | ~5 | GUIDs |

### Special Type Conversions

| SQL Server | PostgreSQL | Tables Affected | Notes |
|------------|-----------|-----------------|-------|
| **IDENTITY(1,1)** | **GENERATED ALWAYS AS IDENTITY** | 91 | NOT SERIAL (per constitution) |
| **nvarchar(50) FK to uid** | **VARCHAR(50) FK to uid** | 2 | material_transition, transition_material |
| **GETDATE()** | **CURRENT_TIMESTAMP** | ~50 | Default values |
| **computed columns** | **GENERATED ALWAYS AS (expr) STORED** | 1 | fatsmurf.run_complete (volatile) |

---

## Foreign Key Constraint Summary

### FK Statistics

| Metric | Count | Notes |
|--------|-------|-------|
| Total FK Constraints | 124 | |
| Named FK Constraints | 99 | |
| Unnamed FK Constraints | 25 | Will receive PG auto-generated names |
| Duplicate FK Constraints | 3 | perseus_user.manufacturer_id (×3) |
| ON DELETE CASCADE | 40 | |
| ON DELETE SET NULL | 4 | |
| ON DELETE NO ACTION | 80 | Default |
| ON UPDATE CASCADE | 2 | UID-based FKs only |
| ON UPDATE NO ACTION | 122 | Default |

### UID-Based Foreign Keys (Special Case)

These 4 FK constraints reference `uid` columns (VARCHAR/nvarchar) instead of integer `id` columns:

| Child Table | Child Column | Parent Table | Parent Column | ON DELETE | ON UPDATE |
|-------------|--------------|--------------|---------------|-----------|-----------|
| material_transition | material_id | goo | uid | CASCADE | **CASCADE** |
| material_transition | transition_id | fatsmurf | uid | CASCADE | NO ACTION |
| transition_material | material_id | goo | uid | CASCADE | **CASCADE** |
| transition_material | transition_id | fatsmurf | uid | CASCADE | NO ACTION |

**Critical Notes:**
1. These are the ONLY constraints with ON UPDATE CASCADE in the entire database
2. Essential for material lineage tracking (P0 critical path)
3. Require indexes on `goo.uid` and `fatsmurf.uid` for performance

---

## Known Issues & Resolutions

### Issue 1: Duplicate Foreign Keys (CRITICAL)

**Severity:** P0 - Blocks deployment
**Table:** perseus_user (creation order #44)
**Description:** 3 duplicate FK constraints to manufacturer.id

| Constraint Name | Column | Parent Table | Parent Column |
|-----------------|--------|--------------|---------------|
| FK__perseus_u__manuf__5B3C942F | manufacturer_id | manufacturer | id |
| FK__perseus_u__manuf__5E1900DA | manufacturer_id | manufacturer | id |
| FK__perseus_u__manuf__6001494C | manufacturer_id | manufacturer | id |

**Root Cause:** SQL Server migration artifact (likely from repeated ALTER TABLE statements)

**Resolution:**
```sql
-- ONLY create ONE FK constraint in PostgreSQL
ALTER TABLE dbo.perseus_user
ADD CONSTRAINT fk_perseus_user_manufacturer
FOREIGN KEY (manufacturer_id)
REFERENCES dbo.manufacturer(id)
ON DELETE NO ACTION
ON UPDATE NO ACTION;
```

**Status:** DOCUMENTED - Fix required during DDL generation

---

### Issue 2: Unnamed Foreign Keys (25 constraints)

**Severity:** P2 - Low priority
**Description:** 25 FK constraints have NULL names in SQL Server metadata

**Affected Tables:**
- feed_type (2 FKs)
- material_inventory (6 FKs)
- material_qc (1 FK)
- recipe (4 FKs)
- recipe_part (5 FKs)
- recipe_project_assignment (1 FK)
- robot_log (1 FK)
- submission (1 FK)
- submission_entry (4 FKs)

**Resolution:** PostgreSQL will auto-generate FK names (e.g., `table_name_column_name_fkey`)

**Status:** ACCEPTED - No action required

---

### Issue 3: Volatile Computed Column (1 instance)

**Severity:** P1 - Must fix before PROD deployment
**Table:** fatsmurf
**Column:** run_complete
**SQL Server DDL:**
```sql
run_complete AS (CASE WHEN [end_time] IS NOT NULL THEN (1) ELSE (0) END)
```

**Issue:** This is a non-deterministic computed column (depends on row state)

**PostgreSQL Resolution:**
```sql
run_complete BOOLEAN GENERATED ALWAYS AS (end_time IS NOT NULL) STORED
```

**Alternative (if STORED fails):**
```sql
-- Create as virtual column (computed on SELECT)
CREATE OR REPLACE VIEW v_fatsmurf AS
SELECT
    *,
    (end_time IS NOT NULL) AS run_complete
FROM dbo.fatsmurf;
```

**Status:** DOCUMENTED - Testing required

---

## Critical Path Tables (P0)

These 8 tables form the core material lineage tracking system:

| Creation Order | Table Name | Tier | Columns | FKs | Notes |
|----------------|------------|------|---------|-----|-------|
| 20 | goo_type | 0 | 12 | 0 | Material type definitions |
| 22 | m_downstream | 0 | 4 | 0 | Cached downstream graph |
| 24 | m_upstream | 0 | 4 | 0 | Cached upstream graph |
| 44 | perseus_user | 1 | 9 | 3 | User records (3 duplicate FKs issue) |
| 70 | fatsmurf | 4 | 18 | 4 | Experiments/transitions (computed column issue) |
| 80 | goo | 5 | 20 | 7 | Materials (core entity) |
| 86 | material_transition | 6 | 3 | 2 | Material-to-transition lineage (UID FKs) |
| 91 | transition_material | 6 | 2 | 2 | Transition-to-material lineage (UID FKs) |

**Dependency Flow:**
```
goo_type (tier 0)
    → perseus_user (tier 1)
        → workflow (tier 2)
            → workflow_step (tier 3)
                → fatsmurf (tier 4)
                    → goo (tier 5)
                        → material_transition + transition_material (tier 6)
```

---

## Index Creation Requirements

### Primary Keys (91 tables)

All 91 dbo tables have PRIMARY KEY constraints using `GENERATED ALWAYS AS IDENTITY`:

```sql
-- Standard pattern (NOT SERIAL per constitution)
id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

### Foreign Key Indexes (124 FKs)

All foreign key columns should have indexes for performance:

```sql
-- Example FK index pattern
CREATE INDEX idx_goo_goo_type_id ON dbo.goo(goo_type_id);
CREATE INDEX idx_goo_added_by ON dbo.goo(added_by);
CREATE INDEX idx_goo_manufacturer_id ON dbo.goo(manufacturer_id);
```

### UID Column Indexes (CRITICAL)

**MANDATORY** indexes for UID-based foreign keys:

```sql
-- goo.uid (referenced by material_transition + transition_material)
CREATE INDEX idx_goo_uid ON dbo.goo(uid);

-- fatsmurf.uid (referenced by material_transition + transition_material)
CREATE INDEX idx_fatsmurf_uid ON dbo.fatsmurf(uid);
```

### Additional Indexes (352 total from SQL Server)

The original SQL Server database has 352 indexes. These will need to be:
1. Analyzed for PostgreSQL equivalence
2. Converted from SQL Server syntax
3. Created after all tables are deployed
4. Performance-tested with EXPLAIN ANALYZE

---

## FDW Table Configuration

### Hermes Schema (6 tables)

**FDW Server:** hermes_fdw
**Extension:** postgres_fdw
**Source Database:** hermes (PostgreSQL)
**Column Correction:** hermes.run has 90 columns (not 8)

```sql
-- Example FDW table creation
CREATE FOREIGN TABLE hermes.run (
    id INTEGER,
    name VARCHAR(255),
    -- ... 88 more columns (90 total)
) SERVER hermes_fdw
OPTIONS (schema_name 'public', table_name 'run');
```

**Tables:**
- run (90 columns) - Fermentation runs
- run_condition (4 columns)
- run_condition_option (4 columns)
- run_condition_value (5 columns)
- run_master_condition (10 columns)
- run_master_condition_type (3 columns)

### Demeter Schema (2 tables)

**FDW Server:** demeter_fdw
**Extension:** postgres_fdw
**Source Database:** demeter (PostgreSQL)
**Column Correction:** demeter.seed_vials has 22 columns (not 11)

```sql
CREATE FOREIGN TABLE demeter.barcodes (
    id INTEGER,
    barcode VARCHAR(50),
    created_at TIMESTAMP
) SERVER demeter_fdw
OPTIONS (schema_name 'public', table_name 'barcodes');

CREATE FOREIGN TABLE demeter.seed_vials (
    id INTEGER,
    -- ... 21 more columns (22 total)
) SERVER demeter_fdw
OPTIONS (schema_name 'public', table_name 'seed_vials');
```

---

## Deployment Checklist

### Pre-Deployment Validation

- [x] All 101 table DDL files generated
- [x] All 101 tables verified for column count match
- [x] Topological sort completed (8 tiers, no circular dependencies)
- [x] All 124 FK relationships documented
- [x] All 3 known issues documented with resolutions
- [ ] Duplicate FK constraint fix applied (perseus_user)
- [ ] Volatile computed column resolution tested (fatsmurf.run_complete)
- [ ] All unnamed FK constraints reviewed
- [ ] FDW server connections configured
- [ ] Index creation scripts prepared (352 indexes)

### Deployment Sequence

1. **Create Schemas**
   ```sql
   CREATE SCHEMA IF NOT EXISTS dbo;
   CREATE SCHEMA IF NOT EXISTS hermes;
   CREATE SCHEMA IF NOT EXISTS demeter;
   ```

2. **Create FDW Extensions & Servers**
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgres_fdw;
   CREATE SERVER hermes_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (...);
   CREATE SERVER demeter_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (...);
   ```

3. **Create DBO Tables (Tier 0-7)**
   - Execute tables 1-92 in creation order
   - Verify each tier completes before starting next tier

4. **Create FDW Tables (8 tables)**
   - Create hermes schema FDW tables (6)
   - Create demeter schema FDW tables (2)

5. **Create Utility Tables (1 table)**
   - perseus_table_and_row_counts

6. **Create Indexes (352 total)**
   - Primary key indexes (auto-created)
   - Foreign key indexes (124 minimum)
   - Additional indexes (228 from SQL Server)

7. **Grant Permissions**
   - Application user permissions
   - Read-only user permissions

### Post-Deployment Validation

- [ ] All 101 tables exist
- [ ] All 124 FK constraints created (121 after duplicate removal)
- [ ] All 352 indexes created
- [ ] All computed columns working
- [ ] FDW tables queryable
- [ ] Sample data queries execute successfully
- [ ] Performance baseline established (EXPLAIN ANALYZE)

---

## Performance Considerations

### Index Strategy

| Index Type | Count | Priority | Notes |
|------------|-------|----------|-------|
| PRIMARY KEY | 91 | P0 | Auto-created with IDENTITY |
| Foreign Key | 124 | P0 | Required for join performance |
| UID Columns | 2 | P0 | goo.uid, fatsmurf.uid (critical) |
| Additional | 228 | P1 | Migrate from SQL Server |

### Query Optimization Targets

Based on SQL Server performance baselines:

| Table | Est. Rows | Critical Queries | Target Latency |
|-------|-----------|------------------|----------------|
| goo | 500K+ | Material lineage traversal | <100ms |
| fatsmurf | 100K+ | Experiment lookup | <50ms |
| material_transition | 1M+ | Lineage joins | <200ms |
| transition_material | 1M+ | Lineage joins | <200ms |
| m_upstream | 2M+ | Cached upstream graph | <50ms |
| m_downstream | 2M+ | Cached downstream graph | <50ms |

### Connection Pool Settings (FDW)

```sql
-- Recommended FDW options for performance
ALTER SERVER hermes_fdw OPTIONS (
    fetch_size '1000',
    use_remote_estimate 'true'
);

ALTER SERVER demeter_fdw OPTIONS (
    fetch_size '500',
    use_remote_estimate 'true'
);
```

---

## Success Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Tables Converted | 101 | 101 | PASS |
| Conversion Errors | 0 | 0 | PASS |
| Column Count Match | 100% | 100% (101/101) | PASS |
| FK Constraints | 124 | 124 | PASS |
| Known Issues Documented | All | 3 | PASS |
| Deployment-Blocking Issues | 0 | 1 | IN PROGRESS |

**Outstanding Work:**
1. Fix duplicate FK constraint (perseus_user) - P0
2. Resolve volatile computed column (fatsmurf.run_complete) - P1
3. Create 352 indexes - P1
4. Performance baseline testing - P1

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 2.0 (Corrected) |
| Created | 2026-02-10 |
| Total Tables | 101 (93 dbo + 8 FDW) |
| Conversion Errors | 0 |
| Column Verification | 100% (101/101) |
| Known Issues | 3 (1 P0, 1 P1, 1 P2) |
| FK Constraints | 124 (121 after duplicate removal) |
| Deployment Status | READY (pending P0 fix) |
| Next Steps | 1) Fix duplicate FK, 2) Test computed column, 3) Create indexes |
