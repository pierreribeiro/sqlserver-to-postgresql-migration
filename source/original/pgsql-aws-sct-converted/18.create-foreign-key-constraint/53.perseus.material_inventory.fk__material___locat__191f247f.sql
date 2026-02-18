ALTER TABLE perseus_dbo.material_inventory
ADD CONSTRAINT fk__material___locat__191f247f FOREIGN KEY (location_container_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

