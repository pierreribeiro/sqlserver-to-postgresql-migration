ALTER TABLE perseus_dbo.transition_material
ADD CONSTRAINT fk_transition_material_goo_946232013 FOREIGN KEY (material_id) 
REFERENCES perseus_dbo.goo (uid)
ON UPDATE CASCADE
ON DELETE CASCADE;

