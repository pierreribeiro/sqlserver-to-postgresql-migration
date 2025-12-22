ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT ck_submission_entry_len_priority CHECK (length(priority::text) <= 6);

