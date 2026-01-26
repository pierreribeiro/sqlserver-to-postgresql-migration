-- ============================================================================
-- Object: history_type
-- Type: TABLE
-- Priority: P2 (Medium - audit system)
-- Description: Lookup table for history event types
-- ============================================================================

DROP TABLE IF EXISTS perseus.history_type CASCADE;

CREATE TABLE perseus.history_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,
    format VARCHAR(200) NOT NULL,

    CONSTRAINT pk_history_type PRIMARY KEY (id)
);

CREATE INDEX idx_history_type_name ON perseus.history_type(name);

COMMENT ON TABLE perseus.history_type IS
'Lookup table for history/audit event types.
Referenced by: history table.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.history_type.id IS 'Primary key';
COMMENT ON COLUMN perseus.history_type.name IS 'Event type name (e.g., "Created", "Updated", "Deleted")';
COMMENT ON COLUMN perseus.history_type.format IS 'Display format string for event';
