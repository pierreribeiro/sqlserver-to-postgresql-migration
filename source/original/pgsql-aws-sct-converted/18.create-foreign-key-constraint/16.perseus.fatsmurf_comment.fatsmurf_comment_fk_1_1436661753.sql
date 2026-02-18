ALTER TABLE perseus_dbo.fatsmurf_comment
ADD CONSTRAINT fatsmurf_comment_fk_1_1436661753 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

