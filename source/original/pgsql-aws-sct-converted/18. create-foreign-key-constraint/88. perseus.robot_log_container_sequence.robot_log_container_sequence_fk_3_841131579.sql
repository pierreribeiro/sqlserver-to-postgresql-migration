ALTER TABLE perseus_dbo.robot_log_container_sequence
ADD CONSTRAINT robot_log_container_sequence_fk_3_841131579 FOREIGN KEY (robot_log_id) 
REFERENCES perseus_dbo.robot_log (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

