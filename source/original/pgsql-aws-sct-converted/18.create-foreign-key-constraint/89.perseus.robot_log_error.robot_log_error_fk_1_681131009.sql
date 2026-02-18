ALTER TABLE perseus_dbo.robot_log_error
ADD CONSTRAINT robot_log_error_fk_1_681131009 FOREIGN KEY (robot_log_id) 
REFERENCES perseus_dbo.robot_log (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

