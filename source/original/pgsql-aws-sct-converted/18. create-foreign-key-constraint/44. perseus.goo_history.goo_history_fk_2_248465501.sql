ALTER TABLE perseus_dbo.goo_history
ADD CONSTRAINT goo_history_fk_2_248465501 FOREIGN KEY (goo_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

