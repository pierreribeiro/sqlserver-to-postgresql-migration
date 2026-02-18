ALTER TABLE perseus_dbo.poll_history
ADD CONSTRAINT poll_history_fk_1_751549961 FOREIGN KEY (history_id) 
REFERENCES perseus_dbo.history (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

