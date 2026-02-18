ALTER TABLE perseus_dbo.material_inventory_threshold
ADD CONSTRAINT fk_material_inventory_threshold_created_by FOREIGN KEY (created_by_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

