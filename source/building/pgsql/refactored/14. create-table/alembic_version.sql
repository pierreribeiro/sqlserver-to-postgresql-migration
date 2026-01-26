-- ============================================================================
-- Object: alembic_version
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: Alembic migration framework version tracking
-- ============================================================================

DROP TABLE IF EXISTS perseus.alembic_version CASCADE;

CREATE TABLE perseus.alembic_version (
    version_num VARCHAR(32) NOT NULL,

    CONSTRAINT pk_alembic_version PRIMARY KEY (version_num)
);

COMMENT ON TABLE perseus.alembic_version IS
'Alembic migration framework version tracking. Single-row table. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.alembic_version.version_num IS 'Current Alembic migration version';
