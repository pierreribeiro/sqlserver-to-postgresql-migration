ALTER TABLE perseus_dbo.material_inventory_threshold
ADD CONSTRAINT fk_material_inventory_threshold_material_type FOREIGN KEY (material_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

