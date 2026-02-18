CREATE TABLE perseus_dbo.workflow_section(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    workflow_id INTEGER NOT NULL,
    name CITEXT NOT NULL,
    starting_step_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

