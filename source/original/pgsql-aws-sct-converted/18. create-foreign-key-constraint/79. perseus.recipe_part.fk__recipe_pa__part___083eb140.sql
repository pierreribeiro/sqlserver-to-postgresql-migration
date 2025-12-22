ALTER TABLE perseus_dbo.recipe_part
ADD CONSTRAINT fk__recipe_pa__part___083eb140 FOREIGN KEY (part_recipe_id) 
REFERENCES perseus_dbo.recipe (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

