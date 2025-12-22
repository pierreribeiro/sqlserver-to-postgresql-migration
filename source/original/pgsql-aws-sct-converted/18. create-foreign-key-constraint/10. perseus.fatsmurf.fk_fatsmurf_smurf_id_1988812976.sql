ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT fk_fatsmurf_smurf_id_1988812976 FOREIGN KEY (smurf_id) 
REFERENCES perseus_dbo.smurf (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

