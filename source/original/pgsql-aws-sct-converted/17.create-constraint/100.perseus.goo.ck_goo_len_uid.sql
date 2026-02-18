ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT ck_goo_len_uid CHECK (length(uid::text) <= 50);

