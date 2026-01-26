-- ============================================================================
-- Object: robot_run
-- Type: TABLE
-- Priority: P2
-- Description: Robot operation run batches
-- ============================================================================

DROP TABLE IF EXISTS perseus.robot_run CASCADE;

CREATE TABLE perseus.robot_run (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    robot_id INTEGER,
    name VARCHAR(200) NOT NULL,
    all_qc_passed BOOLEAN,
    all_themis_submitted BOOLEAN,
    CONSTRAINT pk_robot_run PRIMARY KEY (id)
);

CREATE INDEX idx_robot_run_robot_id ON perseus.robot_run(robot_id);
CREATE INDEX idx_robot_run_name ON perseus.robot_run(name);

COMMENT ON TABLE perseus.robot_run IS
'Robot operation run batches - groups robot operations into named runs.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.robot_run.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.robot_run.robot_id IS 'Robot identifier';
COMMENT ON COLUMN perseus.robot_run.name IS 'Run name/label';
COMMENT ON COLUMN perseus.robot_run.all_qc_passed IS 'Whether all QC checks passed for this run';
COMMENT ON COLUMN perseus.robot_run.all_themis_submitted IS 'Whether all samples were submitted to Themis';
