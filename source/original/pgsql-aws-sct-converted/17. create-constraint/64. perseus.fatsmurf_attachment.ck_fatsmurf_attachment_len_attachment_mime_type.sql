ALTER TABLE perseus_dbo.fatsmurf_attachment
ADD CONSTRAINT ck_fatsmurf_attachment_len_attachment_mime_type CHECK (length(attachment_mime_type::text) <= 150);

