ALTER TABLE perseus_dbo.goo_attachment
ADD CONSTRAINT goo_attachment_fk_1_1072826984 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

