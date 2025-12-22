ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT ck_submission_entry_len_sample_type CHECK (length(sample_type::text) <= 7);

