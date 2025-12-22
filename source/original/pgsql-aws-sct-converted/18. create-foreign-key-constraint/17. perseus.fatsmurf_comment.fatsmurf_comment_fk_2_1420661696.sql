ALTER TABLE perseus_dbo.fatsmurf_comment
ADD CONSTRAINT fatsmurf_comment_fk_2_1420661696 FOREIGN KEY (fatsmurf_id) 
REFERENCES perseus_dbo.fatsmurf (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

