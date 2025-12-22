ALTER TABLE perseus_dbo.container_history
ADD CONSTRAINT container_history_fk_1_1515021770 FOREIGN KEY (history_id) 
REFERENCES perseus_dbo.history (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

