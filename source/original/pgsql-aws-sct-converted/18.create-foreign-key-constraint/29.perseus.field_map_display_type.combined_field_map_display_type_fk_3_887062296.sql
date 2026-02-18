ALTER TABLE perseus_dbo.field_map_display_type
ADD CONSTRAINT combined_field_map_display_type_fk_3_887062296 FOREIGN KEY (display_layout_id) 
REFERENCES perseus_dbo.display_layout (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

