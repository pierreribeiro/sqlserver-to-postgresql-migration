ALTER TABLE perseus_dbo.fatsmurf_attachment
ADD CONSTRAINT ck_fatsmurf_attachment_len_attachment_name CHECK (length(attachment_name::text) <= 150);

