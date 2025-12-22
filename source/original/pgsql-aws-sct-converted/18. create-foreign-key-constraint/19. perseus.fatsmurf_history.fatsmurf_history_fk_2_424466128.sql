ALTER TABLE perseus_dbo.fatsmurf_history
ADD CONSTRAINT fatsmurf_history_fk_2_424466128 FOREIGN KEY (fatsmurf_id) 
REFERENCES perseus_dbo.fatsmurf (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

