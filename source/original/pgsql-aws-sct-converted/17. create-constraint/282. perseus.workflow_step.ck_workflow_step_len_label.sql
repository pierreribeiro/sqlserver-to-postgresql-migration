ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT ck_workflow_step_len_label CHECK (length(label::text) <= 150);

