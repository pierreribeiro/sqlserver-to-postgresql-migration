ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT ck__submissio__sampl__4814495f CHECK (
(sample_type = 'overlay' OR sample_type = 'broth' OR sample_type = 'pellet' OR sample_type = 'none'));

