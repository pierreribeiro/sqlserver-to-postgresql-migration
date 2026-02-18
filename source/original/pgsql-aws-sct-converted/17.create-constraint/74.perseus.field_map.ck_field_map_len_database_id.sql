ALTER TABLE perseus_dbo.field_map
ADD CONSTRAINT ck_field_map_len_database_id CHECK (length(database_id::text) <= 150);

