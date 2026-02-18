ALTER TABLE perseus_dbo.field_map_display_type
ADD CONSTRAINT ck_field_map_display_type_len_display CHECK (length(display::text) <= 150);

