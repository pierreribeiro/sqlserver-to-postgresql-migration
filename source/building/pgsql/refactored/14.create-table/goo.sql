-- Table: perseus.goo
-- Source: SQL Server [dbo].[goo]
-- Columns: 20

CREATE TABLE IF NOT EXISTS perseus.goo (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(250),
    description VARCHAR(1000),
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    original_volume DOUBLE PRECISION DEFAULT 0,
    original_mass DOUBLE PRECISION DEFAULT 0,
    goo_type_id INTEGER NOT NULL DEFAULT 8,
    manufacturer_id INTEGER NOT NULL DEFAULT 1,
    received_on DATE,
    uid VARCHAR(50) NOT NULL,
    project_id SMALLINT,
    container_id INTEGER,
    workflow_step_id INTEGER,
    updated_on TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    inserted_on TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    triton_task_id INTEGER,
    recipe_id INTEGER,
    recipe_part_id INTEGER,
    catalog_label VARCHAR(50)
);
