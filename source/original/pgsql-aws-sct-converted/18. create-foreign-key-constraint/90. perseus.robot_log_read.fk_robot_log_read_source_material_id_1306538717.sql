ALTER TABLE perseus_dbo.robot_log_read
ADD CONSTRAINT fk_robot_log_read_source_material_id_1306538717 FOREIGN KEY (source_material_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

