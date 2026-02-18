ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT fk_goo_recipe_part_1896887812 FOREIGN KEY (recipe_part_id) 
REFERENCES perseus_dbo.recipe_part (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

