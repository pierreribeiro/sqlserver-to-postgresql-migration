ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT fk_goo_workflow_step_430754179 FOREIGN KEY (workflow_step_id) 
REFERENCES perseus_dbo.workflow_step (id)
ON UPDATE NO ACTION
ON DELETE SET NULL;

