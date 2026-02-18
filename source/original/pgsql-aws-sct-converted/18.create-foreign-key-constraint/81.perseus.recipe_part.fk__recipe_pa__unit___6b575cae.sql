ALTER TABLE perseus_dbo.recipe_part
ADD CONSTRAINT fk__recipe_pa__unit___6b575cae FOREIGN KEY (unit_id) 
REFERENCES perseus_dbo.unit (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

