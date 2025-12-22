ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_name CHECK (length(name::text) <= 50);

