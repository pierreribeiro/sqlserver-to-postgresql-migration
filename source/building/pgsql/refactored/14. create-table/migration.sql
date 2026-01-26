-- ============================================================================
-- Object: migration
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: Database migration tracking
-- ============================================================================

DROP TABLE IF EXISTS perseus.migration CASCADE;

CREATE TABLE perseus.migration (
    id INTEGER NOT NULL,
    description VARCHAR(500) NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_migration PRIMARY KEY (id)
);

COMMENT ON TABLE perseus.migration IS
'Database migration tracking table. Records applied schema migrations. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.migration.id IS 'Migration identifier';
COMMENT ON COLUMN perseus.migration.description IS 'Migration description';
COMMENT ON COLUMN perseus.migration.created_on IS 'Timestamp when migration was applied';
