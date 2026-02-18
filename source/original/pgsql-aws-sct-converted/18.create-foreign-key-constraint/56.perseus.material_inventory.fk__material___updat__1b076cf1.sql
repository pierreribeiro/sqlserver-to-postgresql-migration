ALTER TABLE perseus_dbo.material_inventory
ADD CONSTRAINT fk__material___updat__1b076cf1 FOREIGN KEY (updated_by_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

