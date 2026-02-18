CREATE TABLE perseus_dbo.goo(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT,
    description CITEXT,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL,
    original_volume DOUBLE PRECISION DEFAULT (0),
    original_mass DOUBLE PRECISION DEFAULT (0),
    goo_type_id INTEGER NOT NULL DEFAULT (8),
    manufacturer_id INTEGER NOT NULL DEFAULT (1),
    received_on DATE,
    uid CITEXT NOT NULL,
    project_id SMALLINT,
    container_id INTEGER,
    workflow_step_id INTEGER,
    updated_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(),
    inserted_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(),
    triton_task_id INTEGER,
    recipe_id INTEGER,
    recipe_part_id INTEGER,
    catalog_label CITEXT
)
        WITH (
        OIDS=FALSE
        );

