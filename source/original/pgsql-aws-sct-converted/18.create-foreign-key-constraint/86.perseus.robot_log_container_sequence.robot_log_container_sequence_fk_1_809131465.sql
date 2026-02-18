ALTER TABLE perseus_dbo.robot_log_container_sequence
ADD CONSTRAINT robot_log_container_sequence_fk_1_809131465 FOREIGN KEY (sequence_type_id) 
REFERENCES perseus_dbo.sequence_type (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

