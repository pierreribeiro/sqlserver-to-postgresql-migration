-- ============================================================================
-- Object: recipe_project_assignment
-- Type: TABLE
-- Priority: P2
-- Description: Assigns recipes to projects (many-to-many)
-- ============================================================================

DROP TABLE IF EXISTS perseus.recipe_project_assignment CASCADE;

CREATE TABLE perseus.recipe_project_assignment (
    project_id SMALLINT NOT NULL,
    recipe_id INTEGER NOT NULL,
    CONSTRAINT pk_recipe_project_assignment PRIMARY KEY (project_id, recipe_id)
);

CREATE INDEX idx_recipe_project_assignment_recipe_id ON perseus.recipe_project_assignment(recipe_id);
CREATE INDEX idx_recipe_project_assignment_project_id ON perseus.recipe_project_assignment(project_id);

COMMENT ON TABLE perseus.recipe_project_assignment IS
'Assigns recipes to projects (many-to-many relationship) - enables project-specific recipe management.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.recipe_project_assignment.project_id IS 'Project identifier';
COMMENT ON COLUMN perseus.recipe_project_assignment.recipe_id IS 'Foreign key to recipe table';
