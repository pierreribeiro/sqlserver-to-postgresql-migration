ALTER TABLE perseus_dbo.goo_type
ADD CONSTRAINT ck_goo_type_len_abbreviation CHECK (length(abbreviation::text) <= 20);

