ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT fs_container_id_fk_1_1464469833 FOREIGN KEY (container_id) 
REFERENCES perseus_dbo.container (id)
ON UPDATE NO ACTION
ON DELETE SET NULL;

