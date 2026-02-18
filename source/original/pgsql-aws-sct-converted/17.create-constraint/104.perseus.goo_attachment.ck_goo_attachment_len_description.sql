ALTER TABLE perseus_dbo.goo_attachment
ADD CONSTRAINT ck_goo_attachment_len_description CHECK (length(description::text) <= 250);

