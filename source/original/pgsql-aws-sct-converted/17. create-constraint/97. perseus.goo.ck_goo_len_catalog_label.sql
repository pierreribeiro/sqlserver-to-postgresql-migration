ALTER TABLE perseus_dbo.goo
ADD CONSTRAINT ck_goo_len_catalog_label CHECK (length(catalog_label::text) <= 50);

