ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT combined_field_map_fk_2_580405337 FOREIGN KEY (field_map_type_id) 
REFERENCES perseus_dbo.field_map_type (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

