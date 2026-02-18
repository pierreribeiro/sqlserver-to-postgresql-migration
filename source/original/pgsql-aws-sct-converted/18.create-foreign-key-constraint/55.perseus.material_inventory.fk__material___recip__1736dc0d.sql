ALTER TABLE perseus_dbo.material_inventory
ADD CONSTRAINT fk__material___recip__1736dc0d FOREIGN KEY (recipe_id) 
REFERENCES perseus_dbo.recipe (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

