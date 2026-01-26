-- ============================================================================
-- Object: fatsmurf_attachment
-- Type: TABLE
-- Priority: P2
-- Description: Attachments (files/documents) associated with fatsmurf experiments
-- ============================================================================

DROP TABLE IF EXISTS perseus.fatsmurf_attachment CASCADE;

CREATE TABLE perseus.fatsmurf_attachment (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    description TEXT NOT NULL,
    attachment_name VARCHAR(500),
    attachment_mime_type VARCHAR(100),
    attachment BYTEA,
    CONSTRAINT pk_fatsmurf_attachment PRIMARY KEY (id)
);

CREATE INDEX idx_fatsmurf_attachment_fatsmurf_id ON perseus.fatsmurf_attachment(fatsmurf_id);
CREATE INDEX idx_fatsmurf_attachment_added_by ON perseus.fatsmurf_attachment(added_by);

COMMENT ON TABLE perseus.fatsmurf_attachment IS
'Attachments (files/documents) associated with fatsmurf experiments - stores fermentation data, graphs, reports.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.fatsmurf_attachment.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.fatsmurf_attachment.fatsmurf_id IS 'Foreign key to fatsmurf table - parent experiment';
COMMENT ON COLUMN perseus.fatsmurf_attachment.added_on IS 'Timestamp when attachment was added';
COMMENT ON COLUMN perseus.fatsmurf_attachment.added_by IS 'Foreign key to perseus_user - user who added this attachment';
COMMENT ON COLUMN perseus.fatsmurf_attachment.description IS 'Attachment description/notes';
COMMENT ON COLUMN perseus.fatsmurf_attachment.attachment_name IS 'Filename of attachment';
COMMENT ON COLUMN perseus.fatsmurf_attachment.attachment_mime_type IS 'MIME type (e.g., application/pdf, image/png)';
COMMENT ON COLUMN perseus.fatsmurf_attachment.attachment IS 'Binary attachment data (BYTEA)';
