-- ============================================================================
-- Object: robot_log_container_sequence
-- Type: TABLE
-- Priority: P2
-- Description: Robot container movement sequences
-- ============================================================================

DROP TABLE IF EXISTS perseus.robot_log_container_sequence CASCADE;

CREATE TABLE perseus.robot_log_container_sequence (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    sequence_type_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL,
    sequence_number INTEGER NOT NULL,
    CONSTRAINT pk_robot_log_container_sequence PRIMARY KEY (id)
);

CREATE INDEX idx_robot_log_container_sequence_robot_log_id ON perseus.robot_log_container_sequence(robot_log_id);
CREATE INDEX idx_robot_log_container_sequence_container_id ON perseus.robot_log_container_sequence(container_id);

COMMENT ON TABLE perseus.robot_log_container_sequence IS
'Robot container movement sequences - tracks container positions in robot operations.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
