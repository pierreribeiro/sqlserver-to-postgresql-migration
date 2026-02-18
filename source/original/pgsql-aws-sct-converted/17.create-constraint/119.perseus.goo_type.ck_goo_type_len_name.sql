ALTER TABLE perseus_dbo.goo_type
ADD CONSTRAINT ck_goo_type_len_name CHECK (length(name::text) <= 128);

