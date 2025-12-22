ALTER TABLE perseus_dbo.field_map_display_type
ADD CONSTRAINT combined_field_map_display_type_fk_1_596405394 FOREIGN KEY (field_map_id) 
REFERENCES perseus_dbo.field_map (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

