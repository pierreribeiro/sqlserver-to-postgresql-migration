CREATE TABLE perseus_dbo.cm_application(
    application_id INTEGER NOT NULL,
    label CITEXT NOT NULL,
    description CITEXT NOT NULL,
    is_active SMALLINT NOT NULL,
    application_group_id INTEGER,
    url CITEXT,
    owner_user_id INTEGER,
    jira_id CITEXT
)
        WITH (
        OIDS=FALSE
        );

