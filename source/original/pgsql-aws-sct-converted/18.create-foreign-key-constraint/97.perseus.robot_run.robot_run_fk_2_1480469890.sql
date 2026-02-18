ALTER TABLE perseus_dbo.robot_run
ADD CONSTRAINT robot_run_fk_2_1480469890 FOREIGN KEY (robot_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

