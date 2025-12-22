ALTER TABLE perseus_dbo.field_map_type
ADD CONSTRAINT ck_field_map_type_len_name CHECK (length(name::text) <= 50);

