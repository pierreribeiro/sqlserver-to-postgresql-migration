ALTER TABLE perseus_dbo.external_goo_type
ADD CONSTRAINT ck_external_goo_type_len_external_label CHECK (length(external_label::text) <= 250);

