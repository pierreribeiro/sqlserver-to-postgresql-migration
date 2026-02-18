ALTER TABLE perseus_dbo.recipe_part
ADD CONSTRAINT fk__recipe_pa__workf__6c4b80e7 FOREIGN KEY (workflow_step_id) 
REFERENCES perseus_dbo.workflow_step (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

