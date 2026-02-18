ALTER TABLE perseus_dbo.material_transition
ADD CONSTRAINT fk_material_transition_fatsmurf_648466926 FOREIGN KEY (transition_id) 
REFERENCES perseus_dbo.fatsmurf (uid)
ON UPDATE NO ACTION
ON DELETE CASCADE;

