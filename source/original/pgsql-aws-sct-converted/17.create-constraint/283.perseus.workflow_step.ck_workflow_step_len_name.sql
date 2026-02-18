ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT ck_workflow_step_len_name CHECK (length(name::text) <= 150);

