ALTER TABLE perseus_dbo.goo_comment
ADD CONSTRAINT goo_comment_fk_1_1221579390 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

