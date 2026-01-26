-- ============================================================================
-- Object: workflow_section
-- Type: TABLE
-- Priority: P2
-- Description: Sections grouping workflow steps for organization
-- ============================================================================

DROP TABLE IF EXISTS perseus.workflow_section CASCADE;

CREATE TABLE perseus.workflow_section (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    workflow_id INTEGER NOT NULL,
    name VARCHAR(200) NOT NULL,
    starting_step_id INTEGER NOT NULL,
    CONSTRAINT pk_workflow_section PRIMARY KEY (id)
);

CREATE INDEX idx_workflow_section_workflow_id ON perseus.workflow_section(workflow_id);
CREATE INDEX idx_workflow_section_starting_step_id ON perseus.workflow_section(starting_step_id);

COMMENT ON TABLE perseus.workflow_section IS
'Sections grouping workflow steps - enables workflow organization into logical phases.
Example: "Preparation", "Execution", "QC", "Cleanup".
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.workflow_section.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.workflow_section.workflow_id IS 'Foreign key to workflow table';
COMMENT ON COLUMN perseus.workflow_section.name IS 'Section name (e.g., "Preparation", "Execution")';
COMMENT ON COLUMN perseus.workflow_section.starting_step_id IS 'Foreign key to workflow_step - first step in this section';
