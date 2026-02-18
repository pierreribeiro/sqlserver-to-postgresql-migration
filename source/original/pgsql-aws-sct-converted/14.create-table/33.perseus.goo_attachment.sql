CREATE TABLE perseus_dbo.goo_attachment(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL,
    description CITEXT,
    attachment_name CITEXT NOT NULL,
    attachment_mime_type CITEXT,
    attachment BYTEA,
    goo_attachment_type_id INTEGER
)
        WITH (
        OIDS=FALSE
        );

