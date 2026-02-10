-- Table: perseus.cm_application
-- Source: SQL Server [dbo].[cm_application]
-- Columns: 8

CREATE TABLE IF NOT EXISTS perseus.cm_application (
    application_id INTEGER NOT NULL,
    label VARCHAR(50) NOT NULL,
    description VARCHAR(255) NOT NULL,
    is_active SMALLINT NOT NULL,
    application_group_id INTEGER,
    url VARCHAR(255),
    owner_user_id INTEGER,
    jira_id VARCHAR(50)
);
