CREATE TABLE perseus_dbo.person(
    id INTEGER NOT NULL,
    domain_id CITEXT NOT NULL,
    km_session_id CITEXT,
    login CITEXT NOT NULL,
    name CITEXT NOT NULL,
    email CITEXT,
    last_login TIMESTAMP WITHOUT TIME ZONE,
    is_active NUMERIC(1,0) NOT NULL DEFAULT (1)
)
        WITH (
        OIDS=FALSE
        );

