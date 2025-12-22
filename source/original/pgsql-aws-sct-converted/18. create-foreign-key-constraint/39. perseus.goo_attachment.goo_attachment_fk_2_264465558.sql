ALTER TABLE perseus_dbo.goo_attachment
ADD CONSTRAINT goo_attachment_fk_2_264465558 FOREIGN KEY (goo_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

