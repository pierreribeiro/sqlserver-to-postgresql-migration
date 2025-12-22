ALTER TABLE perseus_dbo.goo_type
ADD CONSTRAINT ck_goo_type_len_color CHECK (length(color::text) <= 50);

