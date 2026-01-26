-- ============================================================================
-- Object: goo_attachment
-- Type: TABLE
-- Priority: P1
-- Description: Attachments (files/documents) associated with goo (materials)
-- ============================================================================

DROP TABLE IF EXISTS perseus.goo_attachment CASCADE;

CREATE TABLE perseus.goo_attachment (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    description TEXT,
    attachment_name VARCHAR(500) NOT NULL,
    attachment_mime_type VARCHAR(100),
    attachment BYTEA,
    goo_attachment_type_id INTEGER,
    CONSTRAINT pk_goo_attachment PRIMARY KEY (id)
);

CREATE INDEX idx_goo_attachment_goo_id ON perseus.goo_attachment(goo_id);
CREATE INDEX idx_goo_attachment_added_by ON perseus.goo_attachment(added_by);
CREATE INDEX idx_goo_attachment_type_id ON perseus.goo_attachment(goo_attachment_type_id);

COMMENT ON TABLE perseus.goo_attachment IS
'Attachments (files/documents) associated with goo (materials) - stores COAs, specs, images, etc.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo_attachment.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.goo_attachment.goo_id IS 'Foreign key to goo table - parent material';
COMMENT ON COLUMN perseus.goo_attachment.added_on IS 'Timestamp when attachment was added';
COMMENT ON COLUMN perseus.goo_attachment.added_by IS 'Foreign key to perseus_user - user who added this attachment';
COMMENT ON COLUMN perseus.goo_attachment.description IS 'Attachment description/notes';
COMMENT ON COLUMN perseus.goo_attachment.attachment_name IS 'Filename of attachment';
COMMENT ON COLUMN perseus.goo_attachment.attachment_mime_type IS 'MIME type (e.g., application/pdf, image/png)';
COMMENT ON COLUMN perseus.goo_attachment.attachment IS 'Binary attachment data (BYTEA)';
COMMENT ON COLUMN perseus.goo_attachment.goo_attachment_type_id IS 'Foreign key to goo_attachment_type - type classification';
