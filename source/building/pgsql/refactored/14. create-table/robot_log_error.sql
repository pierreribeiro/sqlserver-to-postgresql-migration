-- ============================================================================
-- Object: robot_log_error
-- Type: TABLE
-- Priority: P2
-- Description: Robot operation errors
-- ============================================================================

DROP TABLE IF EXISTS perseus.robot_log_error CASCADE;

CREATE TABLE perseus.robot_log_error (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    error_message TEXT NOT NULL,
    error_code VARCHAR(50),
    error_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_robot_log_error PRIMARY KEY (id)
);

CREATE INDEX idx_robot_log_error_robot_log_id ON perseus.robot_log_error(robot_log_id);

COMMENT ON TABLE perseus.robot_log_error IS
'Robot operation errors - tracks errors and exceptions during robot runs.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
