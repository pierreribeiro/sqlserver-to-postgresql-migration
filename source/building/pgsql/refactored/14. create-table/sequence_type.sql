-- ============================================================================
-- Object: sequence_type
-- Type: TABLE
-- Priority: P2 (Medium - ID generation)
-- Description: Sequence type definitions for ID generation
-- ============================================================================

DROP TABLE IF EXISTS perseus.sequence_type CASCADE;

CREATE TABLE perseus.sequence_type (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_sequence_type PRIMARY KEY (id)
);

CREATE INDEX idx_sequence_type_name ON perseus.sequence_type(name);

COMMENT ON TABLE perseus.sequence_type IS
'Sequence type definitions for ID generation systems.
Referenced by: robot_log_container_sequence.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.sequence_type.id IS 'Primary key';
COMMENT ON COLUMN perseus.sequence_type.name IS 'Sequence type name';
