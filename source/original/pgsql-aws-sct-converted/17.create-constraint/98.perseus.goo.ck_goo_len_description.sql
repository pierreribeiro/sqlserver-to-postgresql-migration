ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT ck_goo_len_description CHECK (length(description::text) <= 1000);

