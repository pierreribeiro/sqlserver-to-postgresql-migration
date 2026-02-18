ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT fk_workflow_step_property_753515305 FOREIGN KEY (property_id) 
REFERENCES perseus_dbo.property (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

