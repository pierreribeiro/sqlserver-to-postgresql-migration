ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_description CHECK (length(description::text) <= 250);

