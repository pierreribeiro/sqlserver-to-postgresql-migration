CREATE TABLE perseus_dbo.cm_application_group(
    application_group_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    label CITEXT NOT NULL
)
        WITH (
        OIDS=FALSE
        );

