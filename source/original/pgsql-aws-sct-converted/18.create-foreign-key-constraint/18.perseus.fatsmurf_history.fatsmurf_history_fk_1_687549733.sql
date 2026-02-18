ALTER TABLE perseus_dbo.fatsmurf_history
ADD CONSTRAINT fatsmurf_history_fk_1_687549733 FOREIGN KEY (history_id) 
REFERENCES perseus_dbo.history (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

