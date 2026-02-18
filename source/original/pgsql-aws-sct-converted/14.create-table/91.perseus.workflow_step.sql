CREATE TABLE perseus_dbo.workflow_step(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    left_id INTEGER,
    right_id INTEGER,
    scope_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL,
    name CITEXT NOT NULL,
    smurf_id INTEGER,
    goo_type_id INTEGER,
    property_id INTEGER,
    label CITEXT,
    optional SMALLINT NOT NULL DEFAULT (0),
    goo_amount_unit_id INTEGER DEFAULT (61),
    depth INTEGER,
    description CITEXT,
    recipe_factor DOUBLE PRECISION,
    parent_id INTEGER,
    child_order INTEGER
)
        WITH (
        OIDS=FALSE
        );

