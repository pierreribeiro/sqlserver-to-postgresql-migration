ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT fk__submissio__prepp__7d27301c FOREIGN KEY (prepped_by_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

