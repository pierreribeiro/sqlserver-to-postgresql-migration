-- ============================================================================
-- Object: smurf_group_member
-- Type: TABLE
-- Priority: P2
-- Description: Many-to-many relationship between smurfs and smurf_groups
-- ============================================================================

DROP TABLE IF EXISTS perseus.smurf_group_member CASCADE;

CREATE TABLE perseus.smurf_group_member (
    smurf_id INTEGER NOT NULL,
    smurf_group_id INTEGER NOT NULL,
    CONSTRAINT pk_smurf_group_member PRIMARY KEY (smurf_id, smurf_group_id)
);

CREATE INDEX idx_smurf_group_member_smurf_group_id ON perseus.smurf_group_member(smurf_group_id);

COMMENT ON TABLE perseus.smurf_group_member IS
'Many-to-many relationship between smurfs and smurf_groups - enables method grouping.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
