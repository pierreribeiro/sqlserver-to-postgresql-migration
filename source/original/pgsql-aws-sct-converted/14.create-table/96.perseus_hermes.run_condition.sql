CREATE TABLE perseus_hermes.run_condition(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    default_value NUMERIC(11,3),
    condition_set_id INTEGER,
    master_condition_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

