ALTER TABLE perseus_dbo.field_map_set
ADD CONSTRAINT ck_field_map_set_len_color CHECK (length(color::text) <= 50);

