CREATE TABLE perseus_dbo.migration(
    id INTEGER NOT NULL,
    description CITEXT NOT NULL,
    created_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
)
        WITH (
        OIDS=FALSE
        );

