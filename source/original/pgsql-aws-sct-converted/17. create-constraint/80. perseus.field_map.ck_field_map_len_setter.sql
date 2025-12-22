ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_setter CHECK (length(setter::text) <= 150);

