ALTER TABLE perseus_dbo.history_value
ADD CONSTRAINT history_value_fk_1_575549334 FOREIGN KEY (history_id) 
REFERENCES perseus_dbo.history (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

