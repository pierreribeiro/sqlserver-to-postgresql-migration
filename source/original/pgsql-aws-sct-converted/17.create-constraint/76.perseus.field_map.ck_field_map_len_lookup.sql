ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_lookup CHECK (length(lookup::text) <= 150);

