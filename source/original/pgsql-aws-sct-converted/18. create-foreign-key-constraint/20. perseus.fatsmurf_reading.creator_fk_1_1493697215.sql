ALTER TABLE perseus_dbo.fatsmurf_reading
ADD CONSTRAINT creator_fk_1_1493697215 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

