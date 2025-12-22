CREATE TABLE perseus_dbo.cm_group(
    group_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    domain_id CITEXT NOT NULL,
    is_active NUMERIC(1,0) NOT NULL,
    last_modified TIMESTAMP WITHOUT TIME ZONE NOT NULL
)
        WITH (
        OIDS=FALSE
        );

