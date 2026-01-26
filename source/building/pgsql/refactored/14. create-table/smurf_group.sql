-- ============================================================================
-- Object: smurf_group
-- Type: TABLE
-- Priority: P2
-- Description: Groups of smurfs (methods) for organization
-- ============================================================================

DROP TABLE IF EXISTS perseus.smurf_group CASCADE;

CREATE TABLE perseus.smurf_group (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(200) NOT NULL,
    added_by INTEGER NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_smurf_group PRIMARY KEY (id)
);

CREATE INDEX idx_smurf_group_added_by ON perseus.smurf_group(added_by);
CREATE INDEX idx_smurf_group_name ON perseus.smurf_group(name);

COMMENT ON TABLE perseus.smurf_group IS
'Groups of smurfs (methods) for organization - enables method categorization.
Example: "Molecular Biology Methods", "Fermentation Protocols", "QC Tests".
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.smurf_group.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.smurf_group.name IS 'Group name';
COMMENT ON COLUMN perseus.smurf_group.added_by IS 'Foreign key to perseus_user - user who created this group';
COMMENT ON COLUMN perseus.smurf_group.is_public IS 'Whether group is public to all users (default: FALSE)';
