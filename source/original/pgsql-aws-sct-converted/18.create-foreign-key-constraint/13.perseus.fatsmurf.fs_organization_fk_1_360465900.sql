ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT fs_organization_fk_1_360465900 FOREIGN KEY (organization_id) 
REFERENCES perseus_dbo.manufacturer (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

