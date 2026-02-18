ALTER TABLE perseus_dbo.workflow_section
ADD CONSTRAINT workflow_step_start_fk_1_569430194 FOREIGN KEY (starting_step_id) 
REFERENCES perseus_dbo.workflow_step (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

