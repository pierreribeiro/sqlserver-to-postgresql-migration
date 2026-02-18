ALTER TABLE perseus_dbo.workflow
ADD CONSTRAINT ck_workflow_len_name CHECK (length(name::text) <= 150);

