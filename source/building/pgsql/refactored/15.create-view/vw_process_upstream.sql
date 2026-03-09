-- =============================================================================
-- View: perseus.vw_process_upstream
-- Task: T042 (US1 Phase 2)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_process_upstream-analysis.md
-- Description: Exposes process-to-process upstream relationships derived from
--              material lineage. Joins material_transition and transition_material
--              on the shared material_id to identify pairs of process steps
--              connected by a common material. Joins fatsmurf twice (once for each
--              process) to resolve process type identifiers (smurf_id).
-- Dependencies: perseus.material_transition (base table, deployed)
--               perseus.transition_material (base table, deployed)
--               perseus.fatsmurf (base table, deployed)
-- Quality Score: 9.2/10 (post-correction)
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- PRIORITY: P2
-- WAVE: Wave 0 (depends only on base tables, no FDW dependency)
-- BLOCKS: perseus.vw_fermentation_upstream (Wave 1 recursive CTE)
-- T-SQL SOURCE: dbo.vw_process_upstream (WITH SCHEMABINDING removed — not supported
--               in PostgreSQL)
--
-- COLUMN SEMANTICS
-- ----------------
--   source_process:          fatsmurf uid of the downstream (origin) process
--   destination_process:     fatsmurf uid of the upstream (target) process
--   source_process_type:     smurf_id (integer) of the destination process (fs)
--   destination_process_type: smurf_id (integer) of the source process (fs2)
--   connecting_material:     material_id (TEXT) linking the two processes
--
--   NOTE: 'source_process_type' derives from the destination fatsmurf (fs) and
--   'destination_process_type' from the source fatsmurf (fs2). This naming
--   reflects the T-SQL original and is preserved for backward compatibility
--   with all dependent objects.
--
-- P1 CORRECTIONS APPLIED vs AWS SCT OUTPUT
-- -----------------------------------------
--   - Schema: perseus_dbo -> perseus throughout (P1-01)
--   - WITH SCHEMABINDING removed from original T-SQL (P2-01 — not supported in PostgreSQL)
--   - COMMENT ON VIEW added (P2-03)
--   - SELECT column list reformatted to multi-line (P2-04)
--
-- INDEX RECOMMENDATIONS (verify before deploying)
-- -----------------------------------------------
--   fatsmurf.uid          — should be PRIMARY KEY or UNIQUE (used in two JOIN conditions)
--   material_transition.material_id  — index recommended (JOIN condition)
--   transition_material.material_id  — index recommended (JOIN condition)
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_process_upstream (
    source_process,
    destination_process,
    source_process_type,
    destination_process_type,
    connecting_material
) AS
SELECT
    tm.transition_id   AS source_process,
    mt.transition_id   AS destination_process,
    fs.smurf_id        AS source_process_type,
    fs2.smurf_id       AS destination_process_type,
    mt.material_id     AS connecting_material
FROM perseus.material_transition AS mt
JOIN perseus.transition_material AS tm
    ON tm.material_id = mt.material_id
JOIN perseus.fatsmurf AS fs
    ON mt.transition_id = fs.uid
JOIN perseus.fatsmurf AS fs2
    ON tm.transition_id = fs2.uid;

-- =============================================================================

COMMENT ON VIEW perseus.vw_process_upstream IS
    'Process-to-process upstream relationships derived from material lineage. '
    'For each material that connects two process steps, exposes the source process, '
    'destination process, their respective smurf_id type codes, and the connecting '
    'material uid. Used by vw_fermentation_upstream (Wave 1 recursive CTE) to '
    'traverse fermentation process chains (process type = 22). '
    'Depends on: material_transition, transition_material, fatsmurf (all base tables). '
    'T-SQL source: dbo.vw_process_upstream | Migration task T038.';

GRANT SELECT ON perseus.vw_process_upstream TO perseus_app, perseus_readonly;
