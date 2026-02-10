-- Table: perseus.fatsmurf
-- Source: SQL Server [dbo].[fatsmurf]
-- Columns: 18

CREATE TABLE IF NOT EXISTS perseus.fatsmurf (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    smurf_id INTEGER NOT NULL,
    recycled_bottoms_id INTEGER,
    name VARCHAR(150),
    description VARCHAR(500),
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    run_on TIMESTAMP,
    duration DOUBLE PRECISION,
    added_by INTEGER NOT NULL,
    themis_sample_id INTEGER,
    uid VARCHAR(50) NOT NULL,
    -- NOTE: Computed column uses volatile function, cannot be GENERATED STORED,
    -- Original expression: case when duration IS NULL then CURRENT_TIMESTAMP else (run_on + make_interval(minutes => (duration*(60))::integer)) end,
    -- Consider using a trigger or view to compute this value,
    run_complete TIMESTAMP,
    container_id INTEGER,
    organization_id INTEGER DEFAULT 1,
    workflow_step_id INTEGER,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inserted_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    triton_task_id INTEGER
);
