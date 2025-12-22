ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT fk_goo_recipe_1864887698 FOREIGN KEY (recipe_id) 
REFERENCES perseus_dbo.recipe (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

