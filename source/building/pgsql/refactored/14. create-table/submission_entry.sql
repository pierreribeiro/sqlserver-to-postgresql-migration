-- ============================================================================
-- Object: submission_entry
-- Type: TABLE
-- Priority: P2
-- Description: Individual entries in a batch submission
-- ============================================================================

DROP TABLE IF EXISTS perseus.submission_entry CASCADE;

CREATE TABLE perseus.submission_entry (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    submission_id INTEGER NOT NULL,
    smurf_id INTEGER NOT NULL,
    goo_id INTEGER NOT NULL,
    submitter_id INTEGER NOT NULL,
    CONSTRAINT pk_submission_entry PRIMARY KEY (id)
);

CREATE INDEX idx_submission_entry_submission_id ON perseus.submission_entry(submission_id);
CREATE INDEX idx_submission_entry_smurf_id ON perseus.submission_entry(smurf_id);
CREATE INDEX idx_submission_entry_goo_id ON perseus.submission_entry(goo_id);

COMMENT ON TABLE perseus.submission_entry IS
'Individual entries in a batch submission - links submissions to specific materials and methods.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
