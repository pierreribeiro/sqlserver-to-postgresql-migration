ALTER TABLE perseus_dbo.fatsmurf_attachment
ADD CONSTRAINT fatsmurf_attachment_fk_2_440466185 FOREIGN KEY (fatsmurf_id) 
REFERENCES perseus_dbo.fatsmurf (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

