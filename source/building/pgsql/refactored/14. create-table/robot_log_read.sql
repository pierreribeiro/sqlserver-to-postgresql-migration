-- ============================================================================
-- Object: robot_log_read
-- Type: TABLE
-- Priority: P2
-- Description: Robot barcode read events
-- ============================================================================

DROP TABLE IF EXISTS perseus.robot_log_read CASCADE;

CREATE TABLE perseus.robot_log_read (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_log_id INTEGER NOT NULL,
    goo_id INTEGER NOT NULL,
    property_id INTEGER,
    read_value VARCHAR(200),
    read_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_robot_log_read PRIMARY KEY (id)
);

CREATE INDEX idx_robot_log_read_robot_log_id ON perseus.robot_log_read(robot_log_id);
CREATE INDEX idx_robot_log_read_goo_id ON perseus.robot_log_read(goo_id);

COMMENT ON TABLE perseus.robot_log_read IS
'Robot barcode read events - tracks material identification by robots.
Updated: 2026-01-26 | Owner: Perseus DBA Team';
