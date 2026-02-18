ALTER TABLE perseus_dbo.goo_attachment_type
ADD CONSTRAINT ck_goo_attachment_type_len_name CHECK (length(name::text) <= 100);

