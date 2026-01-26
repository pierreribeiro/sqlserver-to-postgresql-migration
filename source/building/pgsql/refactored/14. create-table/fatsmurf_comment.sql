-- ============================================================================
-- Object: fatsmurf_comment
-- Type: TABLE
-- Priority: P2
-- Description: Comments/notes associated with fatsmurf experiments
-- ============================================================================

DROP TABLE IF EXISTS perseus.fatsmurf_comment CASCADE;

CREATE TABLE perseus.fatsmurf_comment (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    comment TEXT NOT NULL,
    CONSTRAINT pk_fatsmurf_comment PRIMARY KEY (id)
);

CREATE INDEX idx_fatsmurf_comment_fatsmurf_id ON perseus.fatsmurf_comment(fatsmurf_id);
CREATE INDEX idx_fatsmurf_comment_added_by ON perseus.fatsmurf_comment(added_by);
CREATE INDEX idx_fatsmurf_comment_added_on ON perseus.fatsmurf_comment(added_on);

COMMENT ON TABLE perseus.fatsmurf_comment IS
'Comments/notes associated with fatsmurf experiments - enables collaborative annotations on fermentation runs.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.fatsmurf_comment.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.fatsmurf_comment.fatsmurf_id IS 'Foreign key to fatsmurf table - parent experiment';
COMMENT ON COLUMN perseus.fatsmurf_comment.added_on IS 'Timestamp when comment was added';
COMMENT ON COLUMN perseus.fatsmurf_comment.added_by IS 'Foreign key to perseus_user - user who added this comment';
COMMENT ON COLUMN perseus.fatsmurf_comment.comment IS 'Comment text';
