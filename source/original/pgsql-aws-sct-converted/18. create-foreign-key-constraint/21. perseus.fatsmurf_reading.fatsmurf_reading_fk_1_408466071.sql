ALTER TABLE perseus_dbo.fatsmurf_reading
ADD CONSTRAINT fatsmurf_reading_fk_1_408466071 FOREIGN KEY (fatsmurf_id) 
REFERENCES perseus_dbo.fatsmurf (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

