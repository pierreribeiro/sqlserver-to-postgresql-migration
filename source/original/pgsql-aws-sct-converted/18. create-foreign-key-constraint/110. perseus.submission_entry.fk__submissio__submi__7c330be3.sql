ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT fk__submissio__submi__7c330be3 FOREIGN KEY (submission_id) 
REFERENCES perseus_dbo.submission (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

