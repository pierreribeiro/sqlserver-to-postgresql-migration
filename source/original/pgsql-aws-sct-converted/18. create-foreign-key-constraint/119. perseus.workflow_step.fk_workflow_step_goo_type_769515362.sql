ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT fk_workflow_step_goo_type_769515362 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

