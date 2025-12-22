ALTER TABLE perseus_dbo.recipe
ADD CONSTRAINT fk__recipe__workflow__64aa5f1f FOREIGN KEY (workflow_id) 
REFERENCES perseus_dbo.workflow (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

