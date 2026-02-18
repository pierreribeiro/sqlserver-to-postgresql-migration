ALTER TABLE perseus_dbo.goo_history
ADD CONSTRAINT goo_history_fk_1_623549505 FOREIGN KEY (history_id) 
REFERENCES perseus_dbo.history (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

