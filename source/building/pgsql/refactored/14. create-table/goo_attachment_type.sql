-- ============================================================================
-- Object: goo_attachment_type
-- Type: TABLE (Tier 0 Lookup)
-- Priority: P2
-- Description: Attachment type definitions for material attachments
-- ============================================================================

DROP TABLE IF EXISTS perseus.goo_attachment_type CASCADE;

CREATE TABLE perseus.goo_attachment_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_goo_attachment_type PRIMARY KEY (id)
);

CREATE INDEX idx_goo_attachment_type_name ON perseus.goo_attachment_type(name);

COMMENT ON TABLE perseus.goo_attachment_type IS
'Attachment type definitions (e.g., "PDF", "Image", "Spec Sheet").
Referenced by: goo_attachment. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.goo_attachment_type.name IS 'Attachment type name';
