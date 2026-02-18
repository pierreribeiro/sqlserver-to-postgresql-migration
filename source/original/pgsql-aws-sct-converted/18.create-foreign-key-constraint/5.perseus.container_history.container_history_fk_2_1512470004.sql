ALTER TABLE perseus_dbo.container_history
ADD CONSTRAINT container_history_fk_2_1512470004 FOREIGN KEY (container_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

