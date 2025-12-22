ALTER TABLE perseus_dbo.material_inventory_threshold_notify_user
ADD CONSTRAINT fk_mit_notify_user_threshold FOREIGN KEY (threshold_id) 
REFERENCES perseus_dbo.material_inventory_threshold (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

