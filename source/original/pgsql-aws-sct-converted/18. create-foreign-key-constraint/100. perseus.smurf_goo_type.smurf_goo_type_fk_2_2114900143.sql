ALTER TABLE perseus_dbo.smurf_goo_type
ADD CONSTRAINT smurf_goo_type_fk_2_2114900143 FOREIGN KEY (goo_type_id) 
REFERENCES perseus_dbo.goo_type (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

