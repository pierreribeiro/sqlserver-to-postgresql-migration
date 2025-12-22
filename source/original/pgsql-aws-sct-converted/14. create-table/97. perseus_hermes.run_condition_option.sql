CREATE TABLE perseus_hermes.run_condition_option(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    value NUMERIC(11,3),
    label CITEXT,
    master_condition_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

