-- ============================================================================
-- Object: workflow_step
-- Type: TABLE
-- Priority: P1
-- Description: Steps in workflows - defines process sequences and operations
-- ============================================================================

DROP TABLE IF EXISTS perseus.workflow_step CASCADE;

CREATE TABLE perseus.workflow_step (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    left_id INTEGER,
    right_id INTEGER,
    scope_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL,
    name VARCHAR(200) NOT NULL,
    smurf_id INTEGER,
    goo_type_id INTEGER,
    property_id INTEGER,
    label VARCHAR(200),
    optional BOOLEAN NOT NULL DEFAULT FALSE,
    goo_amount_unit_id INTEGER DEFAULT 61,
    depth INTEGER,
    description TEXT,
    recipe_factor DOUBLE PRECISION,
    parent_id INTEGER,
    child_order INTEGER,
    CONSTRAINT pk_workflow_step PRIMARY KEY (id)
);

CREATE INDEX idx_workflow_step_scope_id ON perseus.workflow_step(scope_id);
CREATE INDEX idx_workflow_step_class_id ON perseus.workflow_step(class_id);
CREATE INDEX idx_workflow_step_smurf_id ON perseus.workflow_step(smurf_id);
CREATE INDEX idx_workflow_step_goo_type_id ON perseus.workflow_step(goo_type_id);
CREATE INDEX idx_workflow_step_parent_id ON perseus.workflow_step(parent_id);

COMMENT ON TABLE perseus.workflow_step IS
'Steps in workflows - defines process sequences and operations.
Supports hierarchical steps (parent_id, child_order) and branching (left_id, right_id).
Referenced by: goo, fatsmurf, recipe_part (current workflow step).
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.workflow_step.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.workflow_step.left_id IS 'Left branch workflow_step (for branching workflows)';
COMMENT ON COLUMN perseus.workflow_step.right_id IS 'Right branch workflow_step (for branching workflows)';
COMMENT ON COLUMN perseus.workflow_step.scope_id IS 'Scope identifier for step';
COMMENT ON COLUMN perseus.workflow_step.class_id IS 'Class identifier for step type';
COMMENT ON COLUMN perseus.workflow_step.name IS 'Step name/label';
COMMENT ON COLUMN perseus.workflow_step.smurf_id IS 'Foreign key to smurf table - method to execute in this step';
COMMENT ON COLUMN perseus.workflow_step.goo_type_id IS 'Foreign key to goo_type - material type for this step';
COMMENT ON COLUMN perseus.workflow_step.property_id IS 'Foreign key to property - property to measure/track';
COMMENT ON COLUMN perseus.workflow_step.label IS 'Display label for step';
COMMENT ON COLUMN perseus.workflow_step.optional IS 'Whether step is optional (default: FALSE)';
COMMENT ON COLUMN perseus.workflow_step.goo_amount_unit_id IS 'Foreign key to unit table - unit for material amount (default: 61)';
COMMENT ON COLUMN perseus.workflow_step.depth IS 'Hierarchical depth level';
COMMENT ON COLUMN perseus.workflow_step.description IS 'Step description/instructions';
COMMENT ON COLUMN perseus.workflow_step.recipe_factor IS 'Scaling factor for recipe calculations';
COMMENT ON COLUMN perseus.workflow_step.parent_id IS 'Foreign key to workflow_step - parent step in hierarchy';
COMMENT ON COLUMN perseus.workflow_step.child_order IS 'Order among sibling steps';
