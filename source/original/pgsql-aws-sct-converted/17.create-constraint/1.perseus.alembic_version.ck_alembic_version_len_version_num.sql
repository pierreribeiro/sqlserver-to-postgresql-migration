ALTER TABLE perseus_dbo.alembic_version
ADD CONSTRAINT ck_alembic_version_len_version_num CHECK (length(version_num::text) <= 32);

