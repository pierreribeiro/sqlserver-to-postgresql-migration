ALTER TABLE perseus_dbo.submission_entry
ADD CONSTRAINT fk__submissio__assay__78627aff FOREIGN KEY (assay_type_id) 
REFERENCES perseus_dbo.smurf (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

