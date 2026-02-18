ALTER TABLE perseus_dbo.coa_spec
ADD CONSTRAINT ck_coa_spec_len_equal_bound CHECK (length(equal_bound::text) <= 150);

