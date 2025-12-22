ALTER TABLE perseus_dbo.cm_application
ADD CONSTRAINT ck_cm_application_len_jira_id CHECK (length(jira_id::text) <= 50);

