ALTER TABLE perseus_dbo.field_map_block
ADD CONSTRAINT ck_field_map_block_len_scope CHECK (length(scope::text) <= 150);

