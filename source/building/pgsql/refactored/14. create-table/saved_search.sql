-- ============================================================================
-- Object: saved_search
-- Type: TABLE
-- Priority: P2
-- Description: Saved search queries for users
-- ============================================================================

DROP TABLE IF EXISTS perseus.saved_search CASCADE;

CREATE TABLE perseus.saved_search (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER,
    name VARCHAR(200) NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    is_private BOOLEAN NOT NULL DEFAULT TRUE,
    include_downstream BOOLEAN NOT NULL DEFAULT FALSE,
    parameter_string TEXT NOT NULL,
    CONSTRAINT pk_saved_search PRIMARY KEY (id)
);

CREATE INDEX idx_saved_search_added_by ON perseus.saved_search(added_by);
CREATE INDEX idx_saved_search_class_id ON perseus.saved_search(class_id);
CREATE INDEX idx_saved_search_name ON perseus.saved_search(name);

COMMENT ON TABLE perseus.saved_search IS
'Saved search queries for users - enables reusable complex searches.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.saved_search.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.saved_search.class_id IS 'Class identifier for search scope';
COMMENT ON COLUMN perseus.saved_search.name IS 'Search name/label';
COMMENT ON COLUMN perseus.saved_search.added_on IS 'Timestamp when search was created';
COMMENT ON COLUMN perseus.saved_search.added_by IS 'Foreign key to perseus_user - user who created this search';
COMMENT ON COLUMN perseus.saved_search.is_private IS 'Whether search is private to user (default: TRUE)';
COMMENT ON COLUMN perseus.saved_search.include_downstream IS 'Whether to include downstream materials in results (default: FALSE)';
COMMENT ON COLUMN perseus.saved_search.parameter_string IS 'Serialized search parameters (JSON or query string)';
