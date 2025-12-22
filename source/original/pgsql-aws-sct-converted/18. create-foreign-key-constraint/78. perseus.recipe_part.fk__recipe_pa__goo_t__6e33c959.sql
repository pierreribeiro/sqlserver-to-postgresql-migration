ALTER TABLE perseus_dbo.recipe_part
ADD CONSTRAINT fk__recipe_pa__goo_t__6e33c959 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

