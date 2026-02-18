ALTER TABLE perseus_dbo.workflow_step
ADD CONSTRAINT fk_workflow_step_smurf_785515419 FOREIGN KEY (smurf_id) 
REFERENCES perseus_dbo.smurf (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

