ALTER TABLE perseus_dbo.field_map_display_type
ADD CONSTRAINT combined_field_map_display_type_fk_2_871062239 FOREIGN KEY (display_type_id) 
REFERENCES perseus_dbo.display_type (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

