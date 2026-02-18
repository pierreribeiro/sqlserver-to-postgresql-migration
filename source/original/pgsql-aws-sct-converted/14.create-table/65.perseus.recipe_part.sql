CREATE TABLE perseus_dbo.recipe_part(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    recipe_id INTEGER NOT NULL,
    description CITEXT,
    goo_type_id INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    unit_id INTEGER NOT NULL,
    workflow_step_id INTEGER,
    position INTEGER,
    part_recipe_id INTEGER,
    target_conc_in_media DOUBLE PRECISION,
    target_post_inoc_conc DOUBLE PRECISION
)
        WITH (
        OIDS=FALSE
        );

