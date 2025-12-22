ALTER TABLE perseus_dbo.recipe
ADD CONSTRAINT fk__recipe__goo_type__6692a791 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

