-- ============================================================================
-- Object: recipe_part
-- Type: TABLE
-- Priority: P1 - High
-- Description: Components/steps of a recipe (bill of materials)
-- ============================================================================

DROP TABLE IF EXISTS perseus.recipe_part CASCADE;

CREATE TABLE perseus.recipe_part (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    recipe_id INTEGER NOT NULL,
    description TEXT,
    goo_type_id INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    unit_id INTEGER NOT NULL,
    workflow_step_id INTEGER,
    position INTEGER,
    part_recipe_id INTEGER,
    target_conc_in_media DOUBLE PRECISION,
    target_post_inoc_conc DOUBLE PRECISION,
    CONSTRAINT pk_recipe_part PRIMARY KEY (id)
);

CREATE INDEX idx_recipe_part_recipe_id ON perseus.recipe_part(recipe_id);
CREATE INDEX idx_recipe_part_goo_type_id ON perseus.recipe_part(goo_type_id);
CREATE INDEX idx_recipe_part_workflow_step_id ON perseus.recipe_part(workflow_step_id);
CREATE INDEX idx_recipe_part_part_recipe_id ON perseus.recipe_part(part_recipe_id);

COMMENT ON TABLE perseus.recipe_part IS
'Components/steps of a recipe (bill of materials) - defines recipe ingredients and amounts.
Example: recipe_id=10 (LB medium) has parts: water (1L), tryptone (10g), yeast extract (5g), NaCl (10g).
Referenced by: goo (recipe_part_id).
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.recipe_part.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.recipe_part.recipe_id IS 'Foreign key to recipe - parent recipe';
COMMENT ON COLUMN perseus.recipe_part.description IS 'Part description/notes';
COMMENT ON COLUMN perseus.recipe_part.goo_type_id IS 'Foreign key to goo_type - material type for this part';
COMMENT ON COLUMN perseus.recipe_part.amount IS 'Amount of material required';
COMMENT ON COLUMN perseus.recipe_part.unit_id IS 'Foreign key to unit - unit of measurement';
COMMENT ON COLUMN perseus.recipe_part.workflow_step_id IS 'Foreign key to workflow_step - step where this part is added';
COMMENT ON COLUMN perseus.recipe_part.position IS 'Order position in recipe';
COMMENT ON COLUMN perseus.recipe_part.part_recipe_id IS 'Foreign key to recipe - sub-recipe (if this part is made by another recipe)';
COMMENT ON COLUMN perseus.recipe_part.target_conc_in_media IS 'Target concentration in media';
COMMENT ON COLUMN perseus.recipe_part.target_post_inoc_conc IS 'Target concentration post-inoculation';
