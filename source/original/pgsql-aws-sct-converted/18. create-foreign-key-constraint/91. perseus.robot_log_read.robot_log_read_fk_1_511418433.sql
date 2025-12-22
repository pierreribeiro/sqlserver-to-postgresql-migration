ALTER TABLE perseus_dbo.robot_log_read
ADD CONSTRAINT robot_log_read_fk_1_511418433 FOREIGN KEY (robot_log_id) 
REFERENCES perseus_dbo.robot_log (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

