ALTER TABLE perseus_dbo.robot_log_transfer
ADD CONSTRAINT robot_log_transfer_fk_1_463418262 FOREIGN KEY (robot_log_id) 
REFERENCES perseus_dbo.robot_log (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

