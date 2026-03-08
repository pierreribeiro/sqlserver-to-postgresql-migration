-- =============================================================================
-- View: perseus.vw_lot_path
-- Task: T043 (US1 Phase 2 — Wave 1)
-- Source: source/building/pgsql/refactored/15.create-view/analysis/vw_lot_path-analysis.md
-- Description: Pre-computed lot-to-lot upstream lineage paths. Combines
--              m_upstream (populated by reconcile_mupstream) with vw_lot metadata.
-- Dependencies: perseus.m_upstream (base table — populated by reconcile_mupstream),
--               perseus.vw_lot (Wave 0 view — must be deployed first)
-- Quality Score: 9.2/10
-- Author: Migration Team
-- Date: 2026-03-08
-- =============================================================================
--
-- Business logic:
--   The m_upstream table stores pre-computed (start_point, end_point, path, level)
--   tuples where start_point and end_point are material UIDs (goo.uid — TEXT).
--   It is populated by the reconcile_mupstream stored procedure (US1 complete).
--
--   This view joins m_upstream to vw_lot twice to resolve UIDs to integer lot IDs:
--
--     sl (joined on sl.uid = mu.end_point):
--       sl is the lot at the END of the upstream path — the DESCENDANT lot.
--       sl.id becomes src_lot_id.
--
--     dl (joined on dl.uid = mu.start_point):
--       dl is the lot at the START of the upstream path — the ANCESTOR/ORIGIN lot.
--       dl.id becomes dst_lot_id.
--
--   NAMING INVERSION (inherited from T-SQL original — preserved for compatibility):
--     src_lot_id -> DESCENDANT lot  (mu.end_point   -> vw_lot.uid)
--     dst_lot_id -> ANCESTOR lot    (mu.start_point -> vw_lot.uid)
--   Do NOT rename these columns — breaking change for all downstream consumers.
--
--   INNER JOIN: m_upstream rows where start_point or end_point have no matching
--   goo record are excluded (orphaned UIDs are silently dropped).
--
--   path:   Upstream path string from m_upstream (format: /uid1/uid2/...)
--   length: Path depth / hop count from m_upstream.level
--
-- T-SQL transformations applied:
--   - schema:  [dbo] / perseus_dbo -> perseus
--   - quoting: "vw_lot_path"       -> vw_lot_path (no quoting needed)
--   - added:   COMMENT ON VIEW
--
-- Pre-deployment validation:
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema = 'perseus' AND table_name = 'm_upstream'
--   ORDER BY ordinal_position;
--   -- Expected: start_point, end_point (text/varchar), path (text/varchar), level (integer)
-- =============================================================================

CREATE OR REPLACE VIEW perseus.vw_lot_path (
    src_lot_id,
    dst_lot_id,
    path,
    length
) AS
SELECT
    sl.id          AS src_lot_id,
    dl.id          AS dst_lot_id,
    mu.path,
    mu.level       AS length
FROM perseus.m_upstream AS mu
JOIN perseus.vw_lot AS sl
    ON sl.uid = mu.end_point
JOIN perseus.vw_lot AS dl
    ON dl.uid = mu.start_point;

-- Documentation
COMMENT ON VIEW perseus.vw_lot_path IS
    'Pre-computed lot-to-lot upstream lineage paths from m_upstream. '
    'NAMING INVERSION (inherited from T-SQL original — preserved for compatibility): '
    'src_lot_id is the DESCENDANT lot (mu.end_point -> vw_lot.uid); '
    'dst_lot_id is the ANCESTOR/ORIGIN lot (mu.start_point -> vw_lot.uid). '
    'path: upstream path string from m_upstream (format: /uid1/uid2/...). '
    'length: hop count from m_upstream.level. '
    'INNER JOIN: excludes m_upstream rows where start_point or end_point have no goo record. '
    'Requires reconcile_mupstream stored procedure to have populated m_upstream. '
    'Depends on: m_upstream (base table), vw_lot (Wave 0 view). '
    'T-SQL source: dbo.vw_lot_path | Migration task T043 (analysis T038).';

-- Permissions
GRANT SELECT ON perseus.vw_lot_path TO perseus_app, perseus_readonly;
