ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT manufacturer_fk_1_216465387 FOREIGN KEY (manufacturer_id) 
REFERENCES perseus_dbo.manufacturer (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

