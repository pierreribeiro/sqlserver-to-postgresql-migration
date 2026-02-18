ALTER TABLE perseus_dbo.external_goo_type
ADD CONSTRAINT external_goo_type_fk_2_1850697891 FOREIGN KEY (manufacturer_id) 
REFERENCES perseus_dbo.manufacturer (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

