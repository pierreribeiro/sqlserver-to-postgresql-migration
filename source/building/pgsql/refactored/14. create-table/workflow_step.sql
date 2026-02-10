-- Table: perseus.workflow_step
-- Source: SQL Server [dbo].[workflow_step]
-- Columns: 17

CREATE TABLE IF NOT EXISTS perseus.workflow_step (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    left_id INTEGER,
    right_id INTEGER,
    scope_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    smurf_id INTEGER,
    goo_type_id INTEGER,
    property_id INTEGER,
    label VARCHAR(150),
    optional SMALLINT NOT NULL DEFAULT 0,
    goo_amount_unit_id INTEGER DEFAULT 61,
    depth INTEGER,
    description VARCHAR(1000),
    recipe_factor DOUBLE PRECISION,
    parent_id INTEGER,
    child_order INTEGER
);
