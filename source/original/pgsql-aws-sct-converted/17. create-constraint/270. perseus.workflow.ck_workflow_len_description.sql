ALTER TABLE perseus_dbo.workflow
ADD CONSTRAINT ck_workflow_len_description CHECK (length(description::text) <= 1000);

