ALTER TABLE perseus_dbo.container
ADD CONSTRAINT ck_container_len_name CHECK (length(name::text) <= 128);

