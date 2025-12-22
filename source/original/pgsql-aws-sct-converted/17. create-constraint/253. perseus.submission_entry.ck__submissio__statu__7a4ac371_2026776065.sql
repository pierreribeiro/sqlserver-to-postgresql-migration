ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT ck__submissio__statu__7a4ac371_2026776065 CHECK (
(status = 'prepped' OR status = 'submitted_to_themis' OR status = 'prepping' OR status = 'error' OR status = 'to_be_prepped' OR status = 'rejected'));

