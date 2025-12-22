CREATE TABLE perseus_dbo.property_option(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    property_id INTEGER NOT NULL,
    value INTEGER NOT NULL,
    label CITEXT NOT NULL,
    disabled INTEGER NOT NULL DEFAULT (0)
)
        WITH (
        OIDS=FALSE
        );

