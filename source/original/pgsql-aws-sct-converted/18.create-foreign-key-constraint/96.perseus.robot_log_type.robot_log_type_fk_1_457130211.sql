ALTER TABLE perseus_dbo.robot_log_type
ADD CONSTRAINT robot_log_type_fk_1_457130211 FOREIGN KEY (destination_container_type_id) 
REFERENCES perseus_dbo.container_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

