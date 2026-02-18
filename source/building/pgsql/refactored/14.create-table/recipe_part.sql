-- Table: perseus.recipe_part
-- Source: SQL Server [dbo].[recipe_part]
-- Columns: 11

CREATE TABLE IF NOT EXISTS perseus.recipe_part (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    recipe_id INTEGER NOT NULL,
    description TEXT,
    goo_type_id INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    unit_id INTEGER NOT NULL,
    workflow_step_id INTEGER,
    position INTEGER,
    part_recipe_id INTEGER,
    target_conc_in_media DOUBLE PRECISION,
    target_post_inoc_conc DOUBLE PRECISION
);
