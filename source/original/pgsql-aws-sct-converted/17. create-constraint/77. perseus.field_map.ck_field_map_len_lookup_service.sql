ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_lookup_service CHECK (length(lookup_service::text) <= 250);

