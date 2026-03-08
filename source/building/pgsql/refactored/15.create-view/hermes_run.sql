-- =============================================================================
-- View: perseus.hermes_run
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/hermes_run-analysis.md
-- Description: Exposes hermes fermentation run records enriched with local material
--              and container references. Maps hermes run UID strings (e.g. 'm12345')
--              to goo.id integers for the feedstock (input) and resultant (output)
--              materials, and resolves the tank UID to a container record.
--              Only runs with at least one material (feedstock or resultant) are
--              returned, and runs where feedstock == resultant are excluded.
-- Dependencies: hermes.run (FDW via hermes_server — REQUIRED before deployment)
--               perseus.goo (base table, deployed)
--               perseus.container (base table, deployed)
-- Quality Score: 8.4/10 (post-correction)
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- PRIORITY: P1 (High) — FDW-blocked until hermes_server is configured
-- WAVE: Wave 0 (no view dependencies)
-- BLOCKS: Nothing directly. vw_jeremy_runs depends on goo_relationship, not this view.
--
-- FDW DEPENDENCY NOTE
-- -------------------
-- The entire view body drives from hermes.run as the primary table.
-- There is no partial deployment option. The view CANNOT be created until:
--   1. CREATE EXTENSION IF NOT EXISTS postgres_fdw;
--   2. CREATE SERVER hermes_server FOREIGN DATA WRAPPER postgres_fdw
--        OPTIONS (host '...', dbname 'hermes', port '5432');
--   3. CREATE USER MAPPING FOR ... SERVER hermes_server
--        OPTIONS (user '...', password '...');
--   4. hermes.run foreign table is deployed
--        (see source/building/pgsql/refactored/14.create-table/hermes_fdw_setup.sql)
--
-- COLUMN NOTES
-- ------------
--   run_on   -> r.start_time  (TIMESTAMP — when the run started)
--   duration -> r.stop_time   (NUMERIC(10,2) — elapsed run duration in numeric units,
--                              NOT a stop timestamp; unit confirmed with hermes DBA)
--
-- P1 CORRECTIONS APPLIED vs AWS SCT OUTPUT
-- -----------------------------------------
--   - Schema: perseus_dbo -> perseus; perseus_hermes -> hermes (P0-1, P0-2)
--   - Removed all ::CITEXT casts (P1-1): original T-SQL comparisons are case-sensitive;
--     CITEXT would silently change JOIN and WHERE semantics for material UIDs
--   - CAST(rg.id AS VARCHAR(10)) -> rg.id::TEXT (P2-2): idiomatic PostgreSQL
--   - LEFT OUTER JOIN -> LEFT JOIN (P2-1): concise form, semantically identical
--
-- DEPLOYMENT GATE: Verify hermes FDW server is live before running.
--   SELECT srvname FROM pg_foreign_server WHERE srvname = 'hermes_server';
--   Expected: one row returned. If no rows, configure FDW first.
-- =============================================================================

CREATE OR REPLACE VIEW perseus.hermes_run
    (experiment_id, run_id, description, created_on, strain, yield, titer,
     result_goo_id, feedstock_goo_id, container_id, run_on, duration)
AS
SELECT
    r.experiment_id,
    r.local_id                      AS run_id,
    r.description,
    r.created_on,
    r.strain,
    r.max_yield                     AS yield,
    r.max_titer                     AS titer,
    rg.id                           AS result_goo_id,
    ig.id                           AS feedstock_goo_id,
    c.id                            AS container_id,
    r.start_time                    AS run_on,
    -- stop_time is NUMERIC(10,2), representing elapsed run duration.
    -- It is NOT a stop timestamp. Aliased 'duration' per original view contract.
    r.stop_time                     AS duration
FROM hermes.run AS r
-- Resolve resultant_material UID (e.g. 'm12345') to goo.id.
-- The 'm' prefix is a business convention for material UIDs in hermes.
-- Note: this join is non-sargable; see index recommendation below.
LEFT JOIN perseus.goo AS rg
    ON ('m' || rg.id::TEXT) = r.resultant_material
-- Resolve feedstock_material UID (e.g. 'm12345') to goo.id.
LEFT JOIN perseus.goo AS ig
    ON ('m' || ig.id::TEXT) = r.feedstock_material
-- Resolve tank UID to container record.
LEFT JOIN perseus.container AS c
    ON c.uid = r.tank
WHERE
    -- Include only runs with at least one material reference (feedstock OR resultant).
    (COALESCE(r.feedstock_material, '') != ''
     OR COALESCE(r.resultant_material, '') != '')
    -- Exclude runs where feedstock and resultant are the same material
    -- (no meaningful input-to-output transformation occurred).
    AND COALESCE(r.feedstock_material, '') != COALESCE(r.resultant_material, '');

-- =============================================================================

COMMENT ON VIEW perseus.hermes_run IS
    'Hermes fermentation run records enriched with local material and container references. '
    'Maps hermes UID strings (m + goo.id) to perseus.goo integer IDs for feedstock/resultant. '
    'Filters: runs with at least one material, feedstock != resultant. '
    'Column duration = r.stop_time (NUMERIC elapsed time, not a stop timestamp). '
    'P1 - Wave 0. FDW-blocked: requires hermes_server FDW connection. '
    'See hermes_fdw_setup.sql for server configuration.';

GRANT SELECT ON perseus.hermes_run TO perseus_app, perseus_readonly;

-- =============================================================================
-- INDEX RECOMMENDATION (apply after FDW activation if query plan shows seq scans)
-- =============================================================================
-- The LEFT JOIN conditions on goo are non-sargable because a function is applied
-- to the indexed column (goo.id). A functional index makes these joins indexable:
--
--   CREATE INDEX ix_goo_m_uid ON perseus.goo (('m' || id::TEXT));
--
-- FDW FETCH SIZE TUNING (apply after FDW server creation):
--
--   -- For moderate hermes.run row counts (< 100k):
--   ALTER SERVER hermes_server OPTIONS (ADD fetch_size '1000');
--   -- For large hermes.run row counts (>= 100k):
--   ALTER SERVER hermes_server OPTIONS (ADD fetch_size '5000');
-- =============================================================================
