ALTER TABLE perseus_dbo.submission
ADD CONSTRAINT ck_submission_len_label CHECK (length(label::text) <= 100);

