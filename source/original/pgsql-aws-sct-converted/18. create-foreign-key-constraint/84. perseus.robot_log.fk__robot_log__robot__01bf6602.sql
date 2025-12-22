ALTER TABLE perseus_dbo.robot_log
ADD CONSTRAINT fk__robot_log__robot__01bf6602 FOREIGN KEY (robot_log_type_id) 
REFERENCES perseus_dbo.robot_log_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

