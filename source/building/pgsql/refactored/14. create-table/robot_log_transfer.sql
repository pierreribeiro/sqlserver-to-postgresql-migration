-- ============================================================================
-- Object: robot_log_transfer
-- Type: TABLE
-- Priority: P2
-- Description: Robot liquid transfer events
-- ============================================================================

DROP TABLE IF EXISTS perseus.robot_log_transfer CASCADE;

CREATE TABLE perseus.robot_log_transfer (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    source_goo_id INTEGER,
    dest_goo_id INTEGER,
    transfer_volume_ml DOUBLE PRECISION,
    transfer_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_robot_log_transfer PRIMARY KEY (id)
);

CREATE INDEX idx_robot_log_transfer_robot_log_id ON perseus.robot_log_transfer(robot_log_id);
CREATE INDEX idx_robot_log_transfer_source_goo_id ON perseus.robot_log_transfer(source_goo_id);
CREATE INDEX idx_robot_log_transfer_dest_goo_id ON perseus.robot_log_transfer(dest_goo_id);

COMMENT ON TABLE perseus.robot_log_transfer IS
'Robot liquid transfer events - tracks liquid handling operations.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
