ALTER TABLE perseus_dbo.property
ADD CONSTRAINT property_fk_1_741577680 FOREIGN KEY (unit_id) 
REFERENCES perseus_dbo.unit (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

