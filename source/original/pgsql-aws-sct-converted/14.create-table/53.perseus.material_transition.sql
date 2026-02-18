CREATE TABLE perseus_dbo.material_transition(
    material_id CITEXT NOT NULL,
    transition_id CITEXT NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
)
        WITH (
        OIDS=FALSE
        );

