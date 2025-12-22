ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT ck_submission_entry_len_status CHECK (length(status::text) <= 19);

