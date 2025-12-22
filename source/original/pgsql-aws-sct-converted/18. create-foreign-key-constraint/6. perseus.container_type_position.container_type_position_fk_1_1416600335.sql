ALTER TABLE perseus_dbo.container_type_position
ADD CONSTRAINT container_type_position_fk_1_1416600335 FOREIGN KEY (parent_container_type_id) 
REFERENCES perseus_dbo.container_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

