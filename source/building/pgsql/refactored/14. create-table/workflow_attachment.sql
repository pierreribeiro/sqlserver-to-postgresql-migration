-- ============================================================================
-- Object: workflow_attachment
-- Type: TABLE
-- Priority: P2
-- Description: Attachments (files/documents) associated with workflows
-- ============================================================================

DROP TABLE IF EXISTS perseus.workflow_attachment CASCADE;

CREATE TABLE perseus.workflow_attachment (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    workflow_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    attachment_name VARCHAR(500),
    attachment_mime_type VARCHAR(100),
    attachment BYTEA,
    CONSTRAINT pk_workflow_attachment PRIMARY KEY (id)
);

CREATE INDEX idx_workflow_attachment_workflow_id ON perseus.workflow_attachment(workflow_id);
CREATE INDEX idx_workflow_attachment_added_by ON perseus.workflow_attachment(added_by);

COMMENT ON TABLE perseus.workflow_attachment IS
'Attachments (files/documents) associated with workflows - enables workflow documentation.
Example: SOPs, protocols, safety data sheets.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.workflow_attachment.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.workflow_attachment.workflow_id IS 'Foreign key to workflow table';
COMMENT ON COLUMN perseus.workflow_attachment.added_on IS 'Timestamp when attachment was added';
COMMENT ON COLUMN perseus.workflow_attachment.added_by IS 'Foreign key to perseus_user - user who added this attachment';
COMMENT ON COLUMN perseus.workflow_attachment.attachment_name IS 'Filename of attachment';
COMMENT ON COLUMN perseus.workflow_attachment.attachment_mime_type IS 'MIME type (e.g., application/pdf, image/png)';
COMMENT ON COLUMN perseus.workflow_attachment.attachment IS 'Binary attachment data (BYTEA)';
