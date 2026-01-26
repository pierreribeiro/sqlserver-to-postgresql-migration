-- ============================================================================
-- Object: poll_history
-- Type: TABLE
-- Priority: P3
-- Description: Audit trail for poll changes
-- ============================================================================

DROP TABLE IF EXISTS perseus.poll_history CASCADE;

CREATE TABLE perseus.poll_history (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    poll_id INTEGER NOT NULL,
    history_id INTEGER NOT NULL,
    CONSTRAINT pk_poll_history PRIMARY KEY (id)
);

CREATE INDEX idx_poll_history_poll_id ON perseus.poll_history(poll_id);
CREATE INDEX idx_poll_history_history_id ON perseus.poll_history(history_id);

COMMENT ON TABLE perseus.poll_history IS
'Audit trail for poll changes - links polls to history events.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
