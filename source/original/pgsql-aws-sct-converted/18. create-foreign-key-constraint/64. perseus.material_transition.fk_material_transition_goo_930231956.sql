ALTER TABLE perseus_dbo.material_transition
ADD CONSTRAINT fk_material_transition_goo_930231956 FOREIGN KEY (material_id) 
REFERENCES perseus_dbo.goo (uid)
ON UPDATE CASCADE
ON DELETE CASCADE;

