ALTER TABLE perseus_dbo.goo_type
ADD CONSTRAINT ck_goo_type_len_casrn CHECK (length(casrn::text) <= 150);

