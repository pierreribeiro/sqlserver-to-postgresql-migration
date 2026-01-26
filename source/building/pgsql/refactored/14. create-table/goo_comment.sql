-- ============================================================================
-- Object: goo_comment
-- Type: TABLE
-- Priority: P1
-- Description: Comments/notes associated with goo (materials)
-- ============================================================================

DROP TABLE IF EXISTS perseus.goo_comment CASCADE;

CREATE TABLE perseus.goo_comment (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    comment TEXT NOT NULL,
    CONSTRAINT pk_goo_comment PRIMARY KEY (id)
);

CREATE INDEX idx_goo_comment_goo_id ON perseus.goo_comment(goo_id);
CREATE INDEX idx_goo_comment_added_by ON perseus.goo_comment(added_by);
CREATE INDEX idx_goo_comment_added_on ON perseus.goo_comment(added_on);

COMMENT ON TABLE perseus.goo_comment IS
'Comments/notes associated with goo (materials) - enables collaborative annotations.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.goo_comment.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.goo_comment.goo_id IS 'Foreign key to goo table - parent material';
COMMENT ON COLUMN perseus.goo_comment.added_on IS 'Timestamp when comment was added';
COMMENT ON COLUMN perseus.goo_comment.added_by IS 'Foreign key to perseus_user - user who added this comment';
COMMENT ON COLUMN perseus.goo_comment.comment IS 'Comment text';
