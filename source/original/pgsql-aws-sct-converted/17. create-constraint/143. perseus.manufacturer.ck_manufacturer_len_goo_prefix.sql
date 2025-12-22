ALTER TABLE perseus_dbo.manufacturer
ADD CONSTRAINT ck_manufacturer_len_goo_prefix CHECK (length(goo_prefix::text) <= 10);

