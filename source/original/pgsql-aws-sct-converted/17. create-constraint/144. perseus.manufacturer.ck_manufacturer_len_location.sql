ALTER TABLE perseus_dbo.manufacturer
ADD CONSTRAINT ck_manufacturer_len_location CHECK (length(location::text) <= 50);

