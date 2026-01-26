-- ============================================================================
-- Object: feed_type
-- Type: TABLE
-- Priority: P2
-- Description: Feed type definitions for fermentation experiments
-- ============================================================================

DROP TABLE IF EXISTS perseus.feed_type CASCADE;

CREATE TABLE perseus.feed_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    added_by INTEGER NOT NULL,
    updated_by INTEGER,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_feed_type PRIMARY KEY (id)
);

CREATE INDEX idx_feed_type_name ON perseus.feed_type(name);
CREATE INDEX idx_feed_type_added_by ON perseus.feed_type(added_by);

COMMENT ON TABLE perseus.feed_type IS
'Feed type definitions for fermentation experiments (e.g., glucose, glycerol, complex media).
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.feed_type.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.feed_type.name IS 'Feed type name';
COMMENT ON COLUMN perseus.feed_type.description IS 'Feed type description';
COMMENT ON COLUMN perseus.feed_type.added_by IS 'Foreign key to perseus_user - user who created this feed type';
COMMENT ON COLUMN perseus.feed_type.updated_by IS 'Foreign key to perseus_user - user who last updated this feed type';
COMMENT ON COLUMN perseus.feed_type.added_on IS 'Timestamp when record was created';
COMMENT ON COLUMN perseus.feed_type.updated_on IS 'Timestamp when record was last updated';
