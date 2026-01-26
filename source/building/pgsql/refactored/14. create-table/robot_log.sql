-- ============================================================================
-- Object: robot_log
-- Type: TABLE
-- Priority: P2
-- Description: Master table for robot operation logs
-- ============================================================================

DROP TABLE IF EXISTS perseus.robot_log CASCADE;

CREATE TABLE perseus.robot_log (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    class_id INTEGER NOT NULL,
    source VARCHAR(200),
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    log_text TEXT NOT NULL,
    file_name VARCHAR(500),
    robot_log_checksum VARCHAR(100),
    started_on TIMESTAMP,
    completed_on TIMESTAMP,
    loaded_on TIMESTAMP,
    loaded BOOLEAN NOT NULL DEFAULT FALSE,
    loadable BOOLEAN NOT NULL DEFAULT FALSE,
    robot_run_id INTEGER,
    robot_log_type_id INTEGER NOT NULL,
    CONSTRAINT pk_robot_log PRIMARY KEY (id)
);

CREATE INDEX idx_robot_log_class_id ON perseus.robot_log(class_id);
CREATE INDEX idx_robot_log_robot_run_id ON perseus.robot_log(robot_run_id);
CREATE INDEX idx_robot_log_robot_log_type_id ON perseus.robot_log(robot_log_type_id);
CREATE INDEX idx_robot_log_created_on ON perseus.robot_log(created_on);

COMMENT ON TABLE perseus.robot_log IS
'Master table for robot operation logs - stores robot run logs and events.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
