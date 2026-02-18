CREATE TABLE perseus_dbo.perseus_user(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    domain_id CITEXT,
    login CITEXT,
    mail CITEXT,
    admin INTEGER NOT NULL DEFAULT (0),
    super INTEGER NOT NULL DEFAULT (0),
    common_id INTEGER,
    manufacturer_id INTEGER NOT NULL DEFAULT (1)
)
        WITH (
        OIDS=FALSE
        );

