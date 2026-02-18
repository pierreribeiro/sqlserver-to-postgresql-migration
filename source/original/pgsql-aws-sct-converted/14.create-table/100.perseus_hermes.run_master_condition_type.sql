CREATE TABLE perseus_hermes.run_master_condition_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT,
    optional_order INTEGER
)
        WITH (
        OIDS=FALSE
        );

