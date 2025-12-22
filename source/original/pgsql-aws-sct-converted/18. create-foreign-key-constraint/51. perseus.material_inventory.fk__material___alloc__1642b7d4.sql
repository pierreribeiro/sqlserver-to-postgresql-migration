ALTER TABLE perseus_dbo.material_inventory
ADD CONSTRAINT fk__material___alloc__1642b7d4 FOREIGN KEY (allocation_container_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

