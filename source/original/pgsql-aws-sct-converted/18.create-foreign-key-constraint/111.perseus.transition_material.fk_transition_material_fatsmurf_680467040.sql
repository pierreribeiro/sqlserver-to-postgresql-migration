ALTER TABLE perseus_dbo.transition_material
ADD CONSTRAINT fk_transition_material_fatsmurf_680467040 FOREIGN KEY (transition_id) 
REFERENCES perseus_dbo.fatsmurf (uid)
ON UPDATE NO ACTION
ON DELETE CASCADE;

