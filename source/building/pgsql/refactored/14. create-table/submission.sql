-- ============================================================================
-- Object: submission
-- Type: TABLE
-- Priority: P2
-- Description: Batch submission tracking for external systems
-- ============================================================================

DROP TABLE IF EXISTS perseus.submission CASCADE;

CREATE TABLE perseus.submission (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    submitter_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL,
    label VARCHAR(100),
    CONSTRAINT pk_submission PRIMARY KEY (id)
);

CREATE INDEX idx_submission_submitter_id ON perseus.submission(submitter_id);
CREATE INDEX idx_submission_added_on ON perseus.submission(added_on);

COMMENT ON TABLE perseus.submission IS
'Batch submission tracking for external systems (e.g., Themis sample submissions).
Updated: 2026-01-26 | Owner: Perseus DBA Team';
