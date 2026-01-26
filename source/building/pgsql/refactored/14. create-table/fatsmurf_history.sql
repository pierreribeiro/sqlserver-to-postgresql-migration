-- ============================================================================
-- Object: fatsmurf_history
-- Type: TABLE
-- Priority: P2
-- Description: Audit trail for fatsmurf experiment changes
-- ============================================================================

DROP TABLE IF EXISTS perseus.fatsmurf_history CASCADE;

CREATE TABLE perseus.fatsmurf_history (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    history_id INTEGER NOT NULL,
    CONSTRAINT pk_fatsmurf_history PRIMARY KEY (id)
);

CREATE INDEX idx_fatsmurf_history_fatsmurf_id ON perseus.fatsmurf_history(fatsmurf_id);
CREATE INDEX idx_fatsmurf_history_history_id ON perseus.fatsmurf_history(history_id);

COMMENT ON TABLE perseus.fatsmurf_history IS
'Audit trail for fatsmurf experiment changes - links experiments to history events.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.fatsmurf_history.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.fatsmurf_history.fatsmurf_id IS 'Foreign key to fatsmurf table - experiment that changed';
COMMENT ON COLUMN perseus.fatsmurf_history.history_id IS 'Foreign key to history table - the change event';
