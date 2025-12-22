ALTER TABLE perseus_dbo.history
ADD CONSTRAINT history_fk_2_527549163 FOREIGN KEY (history_type_id) 
REFERENCES perseus_dbo.history_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

