ALTER TABLE perseus_dbo.goo_attachment
ADD CONSTRAINT goo_attachment_fk_3_2084943991 FOREIGN KEY (goo_attachment_type_id) 
REFERENCES perseus_dbo.goo_attachment_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

