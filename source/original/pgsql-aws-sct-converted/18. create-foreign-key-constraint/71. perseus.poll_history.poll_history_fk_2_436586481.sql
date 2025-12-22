ALTER TABLE perseus_dbo.poll_history
ADD CONSTRAINT poll_history_fk_2_436586481 FOREIGN KEY (poll_id) 
REFERENCES perseus_dbo.poll (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

