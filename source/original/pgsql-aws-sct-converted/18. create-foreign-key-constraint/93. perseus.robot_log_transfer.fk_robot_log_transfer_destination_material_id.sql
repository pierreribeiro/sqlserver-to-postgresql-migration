ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT fk_robot_log_transfer_destination_material_id FOREIGN KEY (destination_material_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

