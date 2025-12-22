ALTER TABLE perseus_dbo.history
ADD CONSTRAINT history_fk_1_511549106 FOREIGN KEY (creator_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

