ALTER TABLE perseus_dbo.goo_attachment
ADD CONSTRAINT ck_goo_attachment_len_attachment_name CHECK (length(attachment_name::text) <= 150);

