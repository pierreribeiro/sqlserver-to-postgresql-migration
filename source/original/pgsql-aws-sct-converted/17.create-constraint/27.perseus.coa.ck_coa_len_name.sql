ALTER TABLE perseus_dbo.coa
ADD CONSTRAINT ck_coa_len_name CHECK (length(name::text) <= 150);

