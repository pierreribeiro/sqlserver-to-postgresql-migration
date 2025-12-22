ALTER TABLE perseus_dbo.recipe_part
ADD CONSTRAINT fk__recipe_pa__recip__6d3fa520 FOREIGN KEY (recipe_id) 
REFERENCES perseus_dbo.recipe (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

