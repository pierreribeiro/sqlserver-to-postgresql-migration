ALTER TABLE perseus_dbo.migration
ADD CONSTRAINT ck_migration_len_description CHECK (length(description::text) <= 256);

