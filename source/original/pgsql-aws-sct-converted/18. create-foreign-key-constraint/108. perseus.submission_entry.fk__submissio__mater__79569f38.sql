ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT fk__submissio__mater__79569f38 FOREIGN KEY (material_id) 
REFERENCES perseus_dbo.goo (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

