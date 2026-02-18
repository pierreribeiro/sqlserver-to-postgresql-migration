ALTER TABLE perseus_dbo.recipe
ADD CONSTRAINT fk__recipe__added_by__659e8358 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

