CREATE TABLE perseus_dbo.history_value(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    value CITEXT
)
        WITH (
        OIDS=FALSE
        );

