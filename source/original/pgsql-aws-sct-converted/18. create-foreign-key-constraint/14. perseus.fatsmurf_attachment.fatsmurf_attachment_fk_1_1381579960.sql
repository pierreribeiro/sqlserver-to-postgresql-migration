ALTER TABLE perseus_dbo.fatsmurf_attachment
ADD CONSTRAINT fatsmurf_attachment_fk_1_1381579960 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

