ALTER TABLE perseus_dbo.container_type
ADD CONSTRAINT ck_container_type_len_name CHECK (length(name::text) <= 128);

