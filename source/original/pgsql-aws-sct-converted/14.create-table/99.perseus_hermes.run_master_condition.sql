CREATE TABLE perseus_hermes.run_master_condition(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT,
    units CITEXT,
    description CITEXT,
    optional_order INTEGER,
    created_on TIMESTAMP WITHOUT TIME ZONE,
    available_in_view NUMERIC(1,0),
    creator_id INTEGER,
    condition_type_id INTEGER,
    active NUMERIC(1,0)
)
        WITH (
        OIDS=FALSE
        );

