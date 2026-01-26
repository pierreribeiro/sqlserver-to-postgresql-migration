-- ============================================================================
-- Object: m_upstream_dirty_leaves
-- Type: TABLE (Tier 0 - Materialized lineage tracking)
-- Priority: P1
-- Description: Tracks material UIDs requiring upstream lineage recalculation
-- ============================================================================

DROP TABLE IF EXISTS perseus.m_upstream_dirty_leaves CASCADE;

CREATE TABLE perseus.m_upstream_dirty_leaves (
    material_uid VARCHAR(50) NOT NULL,

    CONSTRAINT pk_m_upstream_dirty_leaves PRIMARY KEY (material_uid)
);

CREATE INDEX idx_m_upstream_dirty_leaves_uid ON perseus.m_upstream_dirty_leaves(material_uid);

COMMENT ON TABLE perseus.m_upstream_dirty_leaves IS
'Tracks material UIDs requiring upstream lineage recalculation.
Used by mcgetupstream stored procedure to maintain m_upstream cache.
Working table for incremental lineage updates. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.m_upstream_dirty_leaves.material_uid IS
'Material UID needing upstream lineage refresh (from goo.uid or fatsmurf.uid)';
