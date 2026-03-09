# hermes FDW Mockup — Setup & Operations Guide

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17)
**Purpose:** Local mock of the `hermes` linked server to unblock FDW-dependent view refactoring and validation during US1
**Status:** ✅ DEPLOYED — 2026-02-19
**Related issue:** [#360 — SQL Server Team Decisions Required](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/360) (Topics 3)

---

## Overview

Three views in US1 depend on the SQL Server `hermes` linked server:

| View | hermes objects used | US1 Priority |
|------|---------------------|-------------|
| `goo_relationship` (Branch 3) | `hermes.run` | P1 |
| `hermes_run` | `hermes.run`, `hermes.run_condition_value` | P1 |
| `vw_jeremy_runs` | `hermes.run`, `hermes.run_condition_value` | P3 |

Rather than waiting for the production hermes FDW configuration (pending Issue #360 Topic 3), a **local mock database** was created in the existing Docker PostgreSQL instance. This unblocks DDL validation, syntax testing, and Phase 2 refactoring for these three views.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Docker: perseus-postgres-dev (localhost:5432)       │
│                                                      │
│  ┌────────────────────┐    postgres_fdw              │
│  │ Database: perseus_ │ ──────────────────────────┐  │
│  │ dev                │    hermes_server           │  │
│  │                    │    (host=localhost,        │  │
│  │  schema: hermes    │     port=5432,             │  │
│  │  ├─ hermes.run     │     dbname=hermes)         │  │
│  │  └─ hermes.run_    │                            │  │
│  │     condition_value│◄───────────────────────────┘  │
│  └────────────────────┘                               │
│                          ┌────────────────────┐       │
│                          │ Database: hermes    │       │
│                          │                    │       │
│                          │  schema: public    │       │
│                          │  ├─ public.run     │       │
│                          │  └─ public.run_    │       │
│                          │     condition_value│       │
│                          └────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

---

## Deployed Configuration

### 1. Mock Database (`hermes`)

**Location:** Same Docker instance as `perseus_dev` — `localhost:5432/hermes`

#### `public.run` (mock)

| Column | Type | Notes |
|--------|------|-------|
| `id` | `INTEGER` PK | |
| `experiment_id` | `VARCHAR` | |
| `local_id` | `VARCHAR` | Used as `run_id` alias in `hermes_run` view |
| `description` | `VARCHAR` | |
| `created_on` | `TIMESTAMPTZ` | |
| `strain` | `VARCHAR` | |
| `max_yield` | `DOUBLE PRECISION` | Aliased as `yield` |
| `max_titer` | `DOUBLE PRECISION` | Aliased as `titer` |
| `feedstock_material` | `VARCHAR` | Material UID (e.g. `m12345`) |
| `resultant_material` | `VARCHAR` | Material UID (e.g. `m12346`) |
| `tank` | `VARCHAR` | Container UID |
| `start_time` | `TIMESTAMPTZ` | Aliased as `run_on` |
| `stop_time` | `NUMERIC(10,2)` | ⚠️ Type to confirm — Issue #360 Q3.3 |

#### `public.run_condition_value` (mock)

| Column | Type | Notes |
|--------|------|-------|
| `id` | `INTEGER` PK | |
| `run_id` | `INTEGER` | FK → `run.id` |
| `master_condition_id` | `INTEGER` | Filtered on `= 65` in `vw_jeremy_runs` |
| `value` | `VARCHAR` | |

### 2. Foreign Data Wrapper (in `perseus_dev`)

```sql
-- Extension
postgres_fdw 1.1  (installed in schema: perseus)

-- Server
SERVER hermes_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', port '5432', dbname 'hermes')

-- User mapping
USER MAPPING FOR perseus_admin
  SERVER hermes_server
  (user 'postgres', password '***')

-- Foreign schema (in perseus_dev)
schema: hermes
  ├── hermes.run              → hermes_server :: public.run
  └── hermes.run_condition_value → hermes_server :: public.run_condition_value
```

### 3. Verification

```sql
-- Connectivity test (returns 0 rows — expected, mock tables are empty)
SELECT COUNT(*) FROM hermes.run;              -- 0
SELECT COUNT(*) FROM hermes.run_condition_value;  -- 0
```

---

## DDL Reconstruction (for reference / disaster recovery)

Run these scripts **in order** to rebuild the mockup from scratch.

### Step 1 — Create mock database and tables

```sql
-- Connect to postgres as superuser on the Docker container
-- docker exec -it perseus-postgres-dev psql -U postgres

CREATE DATABASE hermes;
\c hermes

CREATE TABLE public.run (
    id                  INTEGER PRIMARY KEY,
    experiment_id       VARCHAR,
    local_id            VARCHAR,
    description         VARCHAR,
    created_on          TIMESTAMPTZ,
    strain              VARCHAR,
    max_yield           DOUBLE PRECISION,
    max_titer           DOUBLE PRECISION,
    feedstock_material  VARCHAR,
    resultant_material  VARCHAR,
    tank                VARCHAR,
    start_time          TIMESTAMPTZ,
    stop_time           NUMERIC(10,2)   -- ⚠️ confirm type per Issue #360 Q3.3
);

CREATE TABLE public.run_condition_value (
    id                  INTEGER PRIMARY KEY,
    run_id              INTEGER,
    master_condition_id INTEGER,
    value               VARCHAR
);

GRANT SELECT ON ALL TABLES IN SCHEMA public TO perseus_admin;
```

### Step 2 — Configure FDW in `perseus_dev`

```sql
-- Connect to perseus_dev as perseus_admin
-- PGPASSWORD=... psql -h localhost -p 5432 -U perseus_admin -d perseus_dev

CREATE EXTENSION IF NOT EXISTS postgres_fdw
    SCHEMA perseus;

CREATE SERVER hermes_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'hermes');

CREATE USER MAPPING FOR perseus_admin
    SERVER hermes_server
    OPTIONS (user 'postgres', password '<postgres_password>');
-- Password stored at: /Users/pierre.ribeiro/workspace/sharing/
--   sqlserver-to-postgresql-migration/perseus-database/.secrets/postgres_password.txt

CREATE SCHEMA IF NOT EXISTS hermes;

IMPORT FOREIGN SCHEMA public
    FROM SERVER hermes_server
    INTO hermes;
```

### Step 3 — Verify

```sql
\det hermes.*          -- should list run, run_condition_value
SELECT COUNT(*) FROM hermes.run;               -- 0 (empty mock)
SELECT COUNT(*) FROM hermes.run_condition_value;  -- 0 (empty mock)
```

---

## Inserting Mock Data for Testing

Use these snippets to populate the mock tables with enough data to validate view logic:

```sql
-- Connect to hermes database (via docker exec or direct connection)

-- Insert minimal mock run
INSERT INTO public.run VALUES (
    1, 'EXP-001', 'RUN-001', 'Mock fermentation run',
    NOW(), 'E. coli K12',
    85.5, 12.3,
    'm1001',    -- feedstock_material: matches goo.uid pattern
    'm1002',    -- resultant_material
    'TANK-A',
    NOW() - INTERVAL '2 hours',
    120.0       -- stop_time: 120 minutes elapsed (NUMERIC assumption)
);

INSERT INTO public.run_condition_value VALUES
    (1, 1, 65, '2L');   -- master_condition_id=65 = vessel_size condition

-- After inserting, add matching goo rows in perseus_dev:
INSERT INTO perseus.goo (id, uid, name, goo_type_id, added_on, added_by, manufacturer_id)
VALUES
    (1001, 'm1001', 'Mock feedstock', 8, NOW(), 1, 1),
    (1002, 'm1002', 'Mock resultant', 8, NOW(), 1, 1);
```

---

## Known Limitations & TODOs

| Item | Description | Resolution |
|------|-------------|------------|
| `stop_time` type | Currently `NUMERIC(10,2)` — assumed elapsed minutes. May be TIMESTAMPTZ or another type in production | Confirm via Issue #360 Q3.3 |
| Column completeness | Mock `run` table covers only columns referenced by views. Production table likely has additional columns | Issue #360 Q3.1 |
| Empty data | Mock tables are empty — query results will be empty sets | Insert mock rows as needed (see section above) |
| User mapping credentials | Uses Docker `postgres` superuser. Production will use dedicated FDW service account | Update when production FDW is configured |
| `postgres_fdw` schema | Extension installed in `perseus` schema (not `public`) | No functional impact — `postgres_fdw` is schema-agnostic |

---

## Transition to Production hermes FDW

When the production hermes server is available (post Issue #360 Topic 3 resolution):

```sql
-- 1. Drop mock server and mapping
DROP USER MAPPING FOR perseus_admin SERVER hermes_server;
DROP SERVER hermes_server CASCADE;  -- CASCADE drops foreign tables in hermes schema

-- 2. Recreate server pointing to production hermes
CREATE SERVER hermes_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host '<production_hermes_host>',
        port '<port>',
        dbname '<dbname>',
        fetch_size '1000'       -- tune per performance tests
    );

CREATE USER MAPPING FOR perseus_admin
    SERVER hermes_server
    OPTIONS (user '<fdw_user>', password '<fdw_password>');

-- 3. Re-import foreign schema
CREATE SCHEMA IF NOT EXISTS hermes;
IMPORT FOREIGN SCHEMA <hermes_schema>
    FROM SERVER hermes_server
    INTO hermes;

-- 4. Validate views still work
SELECT COUNT(*) FROM hermes.run;
SELECT COUNT(*) FROM hermes.run_condition_value;
```

**Views do not need modification** — they reference `hermes.run` and `hermes.run_condition_value` which remain the same after the server swap, provided the production column names and types match the mock schema. If types diverge, update the foreign table definitions only.

---

## References

- Issue #360: https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/360
- Analysis files: `source/building/pgsql/refactored/15.create-view/analysis/`
  - `goo_relationship-analysis.md`
  - `hermes_run-analysis.md`
  - `vw_jeremy_runs-analysis.md`
- PostgreSQL docs: `CREATE SERVER`, `CREATE USER MAPPING`, `IMPORT FOREIGN SCHEMA`
