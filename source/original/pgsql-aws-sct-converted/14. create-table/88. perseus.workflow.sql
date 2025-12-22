CREATE TABLE perseus_dbo.workflow(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL DEFAULT (23),
    disabled INTEGER NOT NULL DEFAULT (0),
    manufacturer_id INTEGER NOT NULL,
    description CITEXT,
    category CITEXT
)
        WITH (
        OIDS=FALSE
        );

