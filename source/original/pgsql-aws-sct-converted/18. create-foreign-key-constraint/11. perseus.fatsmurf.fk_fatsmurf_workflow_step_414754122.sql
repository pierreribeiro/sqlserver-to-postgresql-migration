ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT fk_fatsmurf_workflow_step_414754122 FOREIGN KEY (workflow_step_id) 
REFERENCES perseus_dbo.workflow_step (id)
ON UPDATE NO ACTION
ON DELETE SET NULL;

