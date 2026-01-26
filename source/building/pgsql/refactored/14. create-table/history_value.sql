-- ============================================================================
-- Object: history_value
-- Type: TABLE
-- Priority: P2
-- Description: Key-value pairs for history event details (audit trail data)
-- ============================================================================

DROP TABLE IF EXISTS perseus.history_value CASCADE;

CREATE TABLE perseus.history_value (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    key VARCHAR(100) NOT NULL,
    value TEXT,
    CONSTRAINT pk_history_value PRIMARY KEY (id)
);

CREATE INDEX idx_history_value_history_id ON perseus.history_value(history_id);
CREATE INDEX idx_history_value_key ON perseus.history_value(key);

COMMENT ON TABLE perseus.history_value IS
'Key-value pairs for history event details - stores detailed audit trail data.
Example: history_id=123, key="old_value", value="10.5" | key="new_value", value="12.3".
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.history_value.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.history_value.history_id IS 'Foreign key to history table - the history event';
COMMENT ON COLUMN perseus.history_value.key IS 'Attribute name (e.g., "old_value", "field_name", "reason")';
COMMENT ON COLUMN perseus.history_value.value IS 'Attribute value (TEXT for flexible storage)';
