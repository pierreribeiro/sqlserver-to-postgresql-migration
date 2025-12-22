ALTER TABLE perseus_dbo.smurf_property
ADD CONSTRAINT smurf_property_fk_1_1138103095 FOREIGN KEY (property_id) 
REFERENCES perseus_dbo.property (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

