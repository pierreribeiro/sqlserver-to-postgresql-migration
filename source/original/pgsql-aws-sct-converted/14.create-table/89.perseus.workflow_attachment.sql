CREATE TABLE perseus_dbo.workflow_attachment(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    workflow_id INTEGER NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL,
    attachment_name CITEXT,
    attachment_mime_type CITEXT,
    attachment BYTEA
)
        WITH (
        OIDS=FALSE
        );

