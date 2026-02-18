ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT ck_workflow_step_len_description CHECK (length(description::text) <= 1000);

