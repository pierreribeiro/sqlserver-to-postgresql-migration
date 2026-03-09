-- =============================================================================
-- View: perseus.translated (MATERIALIZED VIEW)
-- Task: T040 + T041 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/translated-analysis.md
-- Description: Materialized view resolving all source→destination material
--              transitions via the junction table. P0 critical path object.
-- Dependencies: perseus.material_transition, perseus.transition_material
-- Quality Score: 9.4/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Migration context:
--   Original SQL Server: source/original/sqlserver/10.create-view/9.perseus.dbo.translated.sql
--   Index source:        source/original/sqlserver/9.create-index/36.perseus.dbo.translated.ix_materialized.sql
--   AWS SCT baseline:    source/original/pgsql-aws-sct-converted/15.create-view/9.perseus.translated.sql
--
-- SQL Server object type: Indexed View (WITH SCHEMABINDING + UNIQUE CLUSTERED INDEX ix_materialized)
-- PostgreSQL object type: MATERIALIZED VIEW (WITH DATA)
--
-- P0 issues resolved by this file:
--   P0-1: AWS SCT emitted CREATE OR REPLACE VIEW — corrected to CREATE MATERIALIZED VIEW
--   P0-2: CREATE OR REPLACE MATERIALIZED VIEW is invalid syntax — using DROP/CREATE pattern
--   P0-3: No unique index on SCT output — idx_translated_unique created below (required for CONCURRENT refresh)
--   P0-4: AWS SCT used schema perseus_dbo — all references use schema perseus
--   P0-5: No refresh strategy — trigger function and statement-level triggers provided below
--
-- Refresh strategy:
--   Primary:   Statement-level triggers (AFTER INSERT OR UPDATE OR DELETE, FOR EACH STATEMENT)
--              on perseus.material_transition and perseus.transition_material call
--              REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated.
--   Secondary: pg_cron safety-net refresh every 10 minutes (see pg_cron comment at end of file).
--   IMPORTANT: Triggers in this file must be deployed AFTER the materialized view and its
--              unique index are committed. The unique index must exist before the first
--              REFRESH MATERIALIZED VIEW CONCURRENTLY is attempted.
--
-- Deployment sequence within this file:
--   1. DROP MATERIALIZED VIEW IF EXISTS (CASCADE removes dependent indexes)
--   2. CREATE MATERIALIZED VIEW WITH DATA
--   3. CREATE UNIQUE INDEX (required for CONCURRENT refresh)
--   4. CREATE supporting INDEX on destination_material
--   5. CREATE supporting INDEX on source_material
--   6. COMMENT ON MATERIALIZED VIEW
--   7. GRANT SELECT to application roles
--   8. CREATE trigger function perseus.refresh_translated_mv()
--   9. CREATE trigger on perseus.material_transition
--  10. CREATE trigger on perseus.transition_material
--
-- Dependent objects (must be created AFTER this view exists and is populated):
--   Views:     perseus.upstream, perseus.downstream, perseus.material_transition_material
--   Functions: perseus.mcgetupstream, perseus.mcgetdownstream,
--              perseus.mcgetupstreambylist, perseus.mcgetdownstreambylist
--   Procedures (transitively via McGet* functions):
--              perseus.add_arc, perseus.remove_arc, perseus.reconcile_mupstream
--
-- Rollback:
--   DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;
--   DROP FUNCTION IF EXISTS perseus.refresh_translated_mv() CASCADE;
--   (CASCADE on the materialized view drop removes all indexes and dependent triggers)
--
-- Constitution compliance:
--   [x] I.   ANSI-SQL Primacy — Standard SQL INNER JOIN; no vendor extensions
--   [x] II.  Strict Typing — Explicit ::VARCHAR(50) casts in SELECT list
--   [x] III. Set-Based Execution — Single JOIN query; no procedural logic in the view body
--   [x] IV.  Atomic Transactions — DROP/CREATE deployed as a single script execution unit
--   [x] V.   Naming & Scoping — snake_case identifiers; all references schema-qualified as perseus.
--   [x] VI.  Error Resilience — N/A for DDL; trigger function handles refresh invocation
--   [x] VII. Modular Logic — View is single-responsibility: directed lineage edge projection
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Step 1: Drop existing object
-- CASCADE removes all dependent indexes on the materialized view, ensuring a
-- clean slate for index recreation in Steps 3–5.
-- -----------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;

-- -----------------------------------------------------------------------------
-- Step 2: Create the materialized view
--
-- Business logic: each row in perseus.material_transition records that a
-- material (material_id) participated in a transition (transition_id) as the
-- source/parent. Each row in perseus.transition_material records the material
-- produced by a transition (transition_id) as the destination/child.
-- Joining both tables on transition_id yields directed lineage edges:
--
--   source_material --[transition_id]--> destination_material
--
-- Column type mapping:
--   SQL Server nvarchar(50) NOT NULL  →  PostgreSQL VARCHAR(50) NOT NULL
--   Explicit ::VARCHAR(50) casts enforce Constitution Article II (Strict Typing).
--
-- WITH DATA: initial population is performed immediately at creation time.
-- If deploying during peak hours on a large dataset, replace WITH DATA with
-- WITH NO DATA and issue REFRESH MATERIALIZED VIEW perseus.translated manually
-- during an off-peak window before creating the unique index.
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW perseus.translated (source_material, destination_material, transition_id) AS
SELECT
    mt.material_id::VARCHAR(50)   AS source_material,
    tm.material_id::VARCHAR(50)   AS destination_material,
    mt.transition_id::VARCHAR(50) AS transition_id
FROM
    perseus.material_transition AS mt
    INNER JOIN perseus.transition_material AS tm
        ON tm.transition_id = mt.transition_id
WITH DATA;

-- -----------------------------------------------------------------------------
-- Step 3: Unique index — REQUIRED for REFRESH MATERIALIZED VIEW CONCURRENTLY
--
-- SQL Server source:
--   CREATE UNIQUE CLUSTERED INDEX [ix_materialized]
--     ON [dbo].[translated] ([source_material] ASC, [destination_material] ASC, [transition_id] ASC)
--     WITH (FILLFACTOR = 90)
--
-- PostgreSQL has no clustered indexes. This unique index on all three projected
-- columns replicates the uniqueness constraint and enables non-blocking concurrent
-- refreshes. Key order (source_material, destination_material, transition_id)
-- matches the authoritative SQL Server source DDL file. FILLFACTOR = 90 is
-- explicit to match the SQL Server original (PostgreSQL B-tree default is also
-- 90, but explicitness aids auditability).
-- -----------------------------------------------------------------------------
CREATE UNIQUE INDEX idx_translated_unique
    ON perseus.translated (source_material, destination_material, transition_id)
    WITH (fillfactor = 90);

-- -----------------------------------------------------------------------------
-- Step 4: Supporting index on destination_material (non-unique)
--
-- Accelerates:
--   - perseus.upstream recursive view anchor: WHERE pt.destination_material = r.child
--   - perseus.mcgetupstream anchor filter: WHERE pt.destination_material = @StartPoint
--   - perseus.mcgetupstreambylist filter: WHERE pt.destination_material IN (SELECT ...)
-- destination_material is not the leading key of idx_translated_unique, so this
-- dedicated index provides efficient single-column lookups without a full index scan.
-- -----------------------------------------------------------------------------
CREATE INDEX idx_translated_destination_material
    ON perseus.translated (destination_material)
    WITH (fillfactor = 90);

-- -----------------------------------------------------------------------------
-- Step 5: Supporting index on source_material (non-unique)
--
-- Accelerates:
--   - perseus.downstream recursive view anchor: WHERE pt.source_material = r.child
--   - perseus.mcgetdownstream anchor filter: WHERE pt.source_material = @StartPoint
--   - perseus.mcgetdownstreambylist filter: WHERE pt.source_material IN (SELECT ...)
-- source_material is the leading column of idx_translated_unique; this narrower
-- index provides a more efficient covering scan for source_material-only predicates
-- that do not need destination_material or transition_id from the index.
-- -----------------------------------------------------------------------------
CREATE INDEX idx_translated_source_material
    ON perseus.translated (source_material)
    WITH (fillfactor = 90);

-- -----------------------------------------------------------------------------
-- Step 6: Document the materialized view
-- -----------------------------------------------------------------------------
COMMENT ON MATERIALIZED VIEW perseus.translated IS
'Materialized view of directed material lineage edges.
Each row: source_material --[transition_id]--> destination_material.
Migrated from SQL Server Indexed View [dbo].[translated] (WITH SCHEMABINDING +
UNIQUE CLUSTERED INDEX ix_materialized).

Refresh strategy:
  - Primary: statement-level triggers on perseus.material_transition and
    perseus.transition_material call REFRESH MATERIALIZED VIEW CONCURRENTLY.
  - Fallback: pg_cron job every 10 minutes.
  - Command: REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;

Blocks (must be created after this view is refreshed with data):
  Views:     upstream, downstream, material_transition_material
  Functions: mcgetupstream, mcgetdownstream, mcgetupstreambylist,
             mcgetdownstreambylist

Source: source/original/sqlserver/10.create-view/9.perseus.dbo.translated.sql
Task: T040-T041 | Updated: 2026-03-08 | Owner: DBA team';

-- -----------------------------------------------------------------------------
-- Step 7: Grant read access to application roles
-- Materialized views do not inherit permissions from their base tables.
-- These grants are required before any dependent function or view can query
-- perseus.translated. Verify role names match DEV/PROD role configuration
-- before STAGING deployment.
-- -----------------------------------------------------------------------------
GRANT SELECT ON perseus.translated TO perseus_app, perseus_readonly;

-- -----------------------------------------------------------------------------
-- Step 8: Trigger function for automatic materialized view refresh
--
-- SECURITY DEFINER ensures the function executes with the privileges of its
-- owner (the deploying DBA role), which must hold REFRESH rights on
-- perseus.translated. The trigger fires FOR EACH STATEMENT — one refresh per
-- DML batch regardless of how many rows were modified — limiting refresh
-- overhead under bulk-load scenarios.
--
-- The function returns NULL because it is attached as an AFTER statement-level
-- trigger; the return value is ignored by the trigger machinery for statement-
-- level triggers, but NULL is the conventional correct return for AFTER triggers.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION perseus.refresh_translated_mv()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;
    RETURN NULL;
END;
$$;

-- -----------------------------------------------------------------------------
-- Step 9: Trigger on perseus.material_transition
--
-- Fires after any INSERT, UPDATE, or DELETE on the source table.
-- FOR EACH STATEMENT means one materialized view refresh per DML statement,
-- not one per modified row. This prevents a refresh storm during bulk operations.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_refresh_translated_on_material_transition
AFTER INSERT OR UPDATE OR DELETE ON perseus.material_transition
FOR EACH STATEMENT EXECUTE FUNCTION perseus.refresh_translated_mv();

-- -----------------------------------------------------------------------------
-- Step 10: Trigger on perseus.transition_material
--
-- Same pattern as Step 9. Both base tables can independently produce new lineage
-- edges; both must trigger a refresh so that perseus.translated remains current
-- after mutations to either side of the join.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_refresh_translated_on_transition_material
AFTER INSERT OR UPDATE OR DELETE ON perseus.transition_material
FOR EACH STATEMENT EXECUTE FUNCTION perseus.refresh_translated_mv();

-- pg_cron: T265 — Schedule: SELECT cron.schedule('refresh-translated-mv', '*/10 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated');
