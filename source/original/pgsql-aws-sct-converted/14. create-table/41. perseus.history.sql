CREATE TABLE perseus_dbo.history(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_type_id INTEGER NOT NULL,
    creator_id INTEGER NOT NULL,
    created_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
)
        WITH (
        OIDS=FALSE
        );

