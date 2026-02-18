ALTER TABLE perseus_dbo.container
ADD CONSTRAINT container_fk_1_1432469719 FOREIGN KEY (container_type_id) 
REFERENCES perseus_dbo.container_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

