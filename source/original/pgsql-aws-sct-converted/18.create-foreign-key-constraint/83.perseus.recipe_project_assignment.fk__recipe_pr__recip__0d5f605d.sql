ALTER TABLE perseus_dbo.recipe_project_assignment
ADD CONSTRAINT fk__recipe_pr__recip__0d5f605d FOREIGN KEY (recipe_id) 
REFERENCES perseus_dbo.recipe (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

