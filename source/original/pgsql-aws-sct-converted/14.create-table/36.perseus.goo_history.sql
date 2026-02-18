CREATE TABLE perseus_dbo.goo_history(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    goo_id INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

