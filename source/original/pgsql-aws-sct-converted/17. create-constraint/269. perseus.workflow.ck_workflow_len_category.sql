ALTER TABLE perseus_dbo.workflow
ADD CONSTRAINT ck_workflow_len_category CHECK (length(category::text) <= 150);

