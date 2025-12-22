ALTER TABLE perseus_dbo.container
ADD CONSTRAINT ck_container_len_uid CHECK (length(uid::text) <= 50);

