ALTER TABLE perseus_dbo.material_inventory_threshold_notify_user
ADD CONSTRAINT fk_mit_notify_user_user FOREIGN KEY (user_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

