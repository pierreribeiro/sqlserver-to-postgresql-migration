CREATE TABLE perseus_dbo.cm_user(
    user_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    domain_id CITEXT,
    is_active NUMERIC(1,0) NOT NULL,
    name CITEXT NOT NULL,
    login CITEXT,
    email CITEXT,
    object_id UUID
)
        WITH (
        OIDS=FALSE
        );

