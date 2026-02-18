ALTER TABLE perseus_dbo.smurf_property
ADD CONSTRAINT smurf_property_fk_2_1154103152 FOREIGN KEY (smurf_id) 
REFERENCES perseus_dbo.smurf (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

