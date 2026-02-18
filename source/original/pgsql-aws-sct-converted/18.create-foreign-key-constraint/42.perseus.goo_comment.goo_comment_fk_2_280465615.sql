ALTER TABLE perseus_dbo.goo_comment
ADD CONSTRAINT goo_comment_fk_2_280465615 FOREIGN KEY (goo_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

