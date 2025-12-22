ALTER TABLE perseus_dbo.material_inventory
ADD CONSTRAINT fk__material___mater__182b0046 FOREIGN KEY (material_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

