ALTER TABLE perseus_dbo.poll
ADD CONSTRAINT poll_smurf_property_fk_1_420586424 FOREIGN KEY (smurf_property_id) 
REFERENCES perseus_dbo.smurf_property (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

