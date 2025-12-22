ALTER TABLE perseus_dbo.goo_type
ADD CONSTRAINT ck_goo_type_len_iupac CHECK (length(iupac::text) <= 150);

