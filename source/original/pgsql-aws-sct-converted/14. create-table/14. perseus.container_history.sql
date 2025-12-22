CREATE TABLE perseus_dbo.container_history(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

