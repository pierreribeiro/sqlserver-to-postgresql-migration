CREATE TABLE perseus_dbo.fatsmurf(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    smurf_id INTEGER NOT NULL,
    recycled_bottoms_id INTEGER,
    name CITEXT,
    description CITEXT,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    run_on TIMESTAMP WITHOUT TIME ZONE,
    duration DOUBLE PRECISION,
    added_by INTEGER NOT NULL,
    themis_sample_id INTEGER,
    uid CITEXT NOT NULL,
    run_complete TIMESTAMP WITHOUT TIME ZONE,
    container_id INTEGER,
    organization_id INTEGER DEFAULT (1),
    workflow_step_id INTEGER,
    updated_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(),
    inserted_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(),
    triton_task_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

