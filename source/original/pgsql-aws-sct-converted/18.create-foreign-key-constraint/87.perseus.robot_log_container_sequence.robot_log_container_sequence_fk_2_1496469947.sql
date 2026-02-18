ALTER TABLE perseus_dbo.robot_log_container_sequence
ADD CONSTRAINT robot_log_container_sequence_fk_2_1496469947 FOREIGN KEY (container_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

