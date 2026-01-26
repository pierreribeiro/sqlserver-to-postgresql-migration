-- ============================================================================
-- Object: goo_history
-- Type: TABLE
-- Priority: P1
-- Description: Audit trail for goo (material) changes
-- ============================================================================

DROP TABLE IF EXISTS perseus.goo_history CASCADE;

CREATE TABLE perseus.goo_history (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    history_id INTEGER NOT NULL,
    CONSTRAINT pk_goo_history PRIMARY KEY (id)
);

CREATE INDEX idx_goo_history_goo_id ON perseus.goo_history(goo_id);
CREATE INDEX idx_goo_history_history_id ON perseus.goo_history(history_id);

COMMENT ON TABLE perseus.goo_history IS
'Audit trail for goo (material) changes - links materials to history events.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo_history.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.goo_history.goo_id IS 'Foreign key to goo table - material that changed';
COMMENT ON COLUMN perseus.goo_history.history_id IS 'Foreign key to history table - the change event';
