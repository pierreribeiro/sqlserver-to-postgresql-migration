CREATE TABLE perseus_hermes.run_condition_value(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    value NUMERIC(11,3),
    master_condition_id INTEGER,
    updated_on TIMESTAMP WITHOUT TIME ZONE,
    run_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

