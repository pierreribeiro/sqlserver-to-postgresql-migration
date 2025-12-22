CREATE TABLE perseus_dbo.fatsmurf_history(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    fatsmurf_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

