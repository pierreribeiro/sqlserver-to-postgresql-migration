ALTER TABLE perseus_dbo.smurf_goo_type
ADD CONSTRAINT smurf_goo_type_fk_1_933578364 FOREIGN KEY (smurf_id) 
REFERENCES perseus_dbo.smurf (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

