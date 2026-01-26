-- ============================================================================
-- Object: workflow_step_type
-- Type: TABLE
-- Priority: P2 (Medium - workflow system)
-- Description: Workflow step type definitions
-- ============================================================================

DROP TABLE IF EXISTS perseus.workflow_step_type CASCADE;

CREATE TABLE perseus.workflow_step_type (
    id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,

    CONSTRAINT pk_workflow_step_type PRIMARY KEY (id)
);

CREATE INDEX idx_workflow_step_type_name ON perseus.workflow_step_type(name);

COMMENT ON TABLE perseus.workflow_step_type IS
'Workflow step type definitions (e.g., "manual", "automated", "approval").
Referenced by: workflow_step table.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.workflow_step_type.id IS 'Primary key';
COMMENT ON COLUMN perseus.workflow_step_type.name IS 'Step type name';
