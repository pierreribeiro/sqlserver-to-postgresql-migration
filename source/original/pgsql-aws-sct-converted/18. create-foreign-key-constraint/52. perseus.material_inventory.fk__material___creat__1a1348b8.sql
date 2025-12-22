ALTER TABLE perseus_dbo.material_inventory
ADD CONSTRAINT fk__material___creat__1a1348b8 FOREIGN KEY (created_by_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

