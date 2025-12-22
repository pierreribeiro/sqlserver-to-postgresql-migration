ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_onchange CHECK (length(onchange::text) <= 150);

