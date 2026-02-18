ALTER TABLE perseus_dbo.submission
ADD CONSTRAINT fk__submissio__submi__739dc5e2 FOREIGN KEY (submitter_id) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

