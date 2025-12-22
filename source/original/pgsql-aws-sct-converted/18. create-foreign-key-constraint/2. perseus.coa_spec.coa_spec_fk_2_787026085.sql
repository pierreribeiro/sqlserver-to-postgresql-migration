ALTER TABLE perseus_dbo.coa_spec
ADD CONSTRAINT coa_spec_fk_2_787026085 FOREIGN KEY (property_id) 
REFERENCES perseus_dbo.property (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

