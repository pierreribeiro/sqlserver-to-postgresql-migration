ALTER TABLE perseus_dbo.goo_attachment
ADD CONSTRAINT ck_goo_attachment_len_attachment_mime_type CHECK (length(attachment_mime_type::text) <= 150);

