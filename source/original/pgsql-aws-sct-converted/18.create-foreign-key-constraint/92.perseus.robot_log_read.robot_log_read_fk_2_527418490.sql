ALTER TABLE perseus_dbo.robot_log_read
ADD CONSTRAINT robot_log_read_fk_2_527418490 FOREIGN KEY (property_id) 
REFERENCES perseus_dbo.property (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

