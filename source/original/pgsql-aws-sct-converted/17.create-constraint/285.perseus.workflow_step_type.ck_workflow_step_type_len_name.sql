ALTER TABLE perseus_dbo.workflow_step_type
ADD CONSTRAINT ck_workflow_step_type_len_name CHECK (length(name::text) <= 150);

