ALTER TABLE perseus_dbo.external_goo_type
ADD CONSTRAINT external_goo_type_fk_1_31416723 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

