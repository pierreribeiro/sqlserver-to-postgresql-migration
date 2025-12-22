CREATE TABLE perseus_dbo.prefix_incrementor(
    prefix CITEXT NOT NULL,
    counter INTEGER NOT NULL
)
        WITH (
        OIDS=FALSE
        );

