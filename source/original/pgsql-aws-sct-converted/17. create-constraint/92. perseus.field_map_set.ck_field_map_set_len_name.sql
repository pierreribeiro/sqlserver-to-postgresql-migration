ALTER TABLE perseus_dbo.field_map_set
ADD CONSTRAINT ck_field_map_set_len_name CHECK (length(name::text) <= 50);

