ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT ck__submissio__prior__7b3ee7aa CHECK (
(priority = 'normal' OR priority = 'urgent'));

