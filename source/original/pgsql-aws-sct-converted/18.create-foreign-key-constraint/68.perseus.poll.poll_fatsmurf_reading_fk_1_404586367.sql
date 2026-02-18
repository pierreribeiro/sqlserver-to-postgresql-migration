ALTER TABLE perseus_dbo.poll
ADD CONSTRAINT poll_fatsmurf_reading_fk_1_404586367 FOREIGN KEY (fatsmurf_reading_id) 
REFERENCES perseus_dbo.fatsmurf_reading (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

