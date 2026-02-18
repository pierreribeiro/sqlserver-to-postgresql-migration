ALTER TABLE perseus_dbo.container_type_position
ADD CONSTRAINT container_type_position_fk_2_1206984818 FOREIGN KEY (child_container_type_id) 
REFERENCES perseus_dbo.container_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

