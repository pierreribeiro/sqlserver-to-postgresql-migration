CREATE TABLE perseus_dbo.poll_history(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    poll_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

