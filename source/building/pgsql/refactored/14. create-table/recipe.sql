-- ============================================================================
-- Object: recipe
-- Type: TABLE
-- Priority: P1 - High
-- Description: Recipe definitions for material production
-- ============================================================================

DROP TABLE IF EXISTS perseus.recipe CASCADE;

CREATE TABLE perseus.recipe (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(200) NOT NULL,
    goo_type_id INTEGER NOT NULL,
    description TEXT,
    sop TEXT,
    workflow_id INTEGER,
    added_by INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL,
    is_preferred BOOLEAN NOT NULL DEFAULT FALSE,
    qc BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    feed_type_id INTEGER,
    stock_concentration DOUBLE PRECISION,
    sterilization_method VARCHAR(100),
    inoculant_percent DOUBLE PRECISION,
    post_inoc_volume_ml DOUBLE PRECISION,
    CONSTRAINT pk_recipe PRIMARY KEY (id)
);

CREATE INDEX idx_recipe_goo_type_id ON perseus.recipe(goo_type_id);
CREATE INDEX idx_recipe_workflow_id ON perseus.recipe(workflow_id);
CREATE INDEX idx_recipe_added_by ON perseus.recipe(added_by);
CREATE INDEX idx_recipe_feed_type_id ON perseus.recipe(feed_type_id);
CREATE INDEX idx_recipe_name ON perseus.recipe(name);

COMMENT ON TABLE perseus.recipe IS
'Recipe definitions for material production - defines how to create materials.
Referenced by: goo, material_inventory, recipe_part.
Updated: 2026-01-26 | Owner: Perseus DBA Team';

COMMENT ON COLUMN perseus.recipe.id IS 'Primary key - unique identifier (auto-increment)';
COMMENT ON COLUMN perseus.recipe.name IS 'Recipe name/label';
COMMENT ON COLUMN perseus.recipe.goo_type_id IS 'Foreign key to goo_type - type of material this recipe produces';
COMMENT ON COLUMN perseus.recipe.description IS 'Recipe description/notes';
COMMENT ON COLUMN perseus.recipe.sop IS 'Standard Operating Procedure (SOP) text';
COMMENT ON COLUMN perseus.recipe.workflow_id IS 'Foreign key to workflow - associated workflow';
COMMENT ON COLUMN perseus.recipe.added_by IS 'Foreign key to perseus_user - user who created this recipe';
COMMENT ON COLUMN perseus.recipe.added_on IS 'Timestamp when recipe was created';
COMMENT ON COLUMN perseus.recipe.is_preferred IS 'Whether this is the preferred recipe for this goo_type (default: FALSE)';
COMMENT ON COLUMN perseus.recipe.qc IS 'Whether QC is required (default: FALSE)';
COMMENT ON COLUMN perseus.recipe.is_archived IS 'Whether recipe is archived (default: FALSE)';
COMMENT ON COLUMN perseus.recipe.feed_type_id IS 'Foreign key to feed_type - fermentation feed type';
COMMENT ON COLUMN perseus.recipe.stock_concentration IS 'Stock concentration (for dilution calculations)';
COMMENT ON COLUMN perseus.recipe.sterilization_method IS 'Sterilization method (e.g., autoclaving, filtering)';
COMMENT ON COLUMN perseus.recipe.inoculant_percent IS 'Inoculant percentage for fermentation';
COMMENT ON COLUMN perseus.recipe.post_inoc_volume_ml IS 'Post-inoculation volume in milliliters';
