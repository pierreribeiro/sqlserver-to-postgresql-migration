ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT ck_goo_len_name CHECK (length(name::text) <= 250);

