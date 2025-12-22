ALTER TABLE perseus_dbo.property_option
ADD CONSTRAINT property_option_fk_1_1462504489 FOREIGN KEY (property_id) 
REFERENCES perseus_dbo.property (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

