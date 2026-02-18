ALTER TABLE perseus_dbo.robot_log
ADD CONSTRAINT robot_log_fk_1_617130781 FOREIGN KEY (robot_run_id) 
REFERENCES perseus_dbo.robot_run (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

