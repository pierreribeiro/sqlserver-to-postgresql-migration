ALTER TABLE perseus_dbo.manufacturer
ADD CONSTRAINT ck_manufacturer_len_name CHECK (length(name::text) <= 128);

