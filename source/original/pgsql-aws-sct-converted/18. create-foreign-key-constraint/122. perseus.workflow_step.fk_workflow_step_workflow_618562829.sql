ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT fk_workflow_step_workflow_618562829 FOREIGN KEY (scope_id) 
REFERENCES perseus_dbo.workflow (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

