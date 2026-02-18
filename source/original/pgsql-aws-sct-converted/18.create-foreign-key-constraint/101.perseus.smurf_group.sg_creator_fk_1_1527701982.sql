ALTER TABLE perseus_dbo.smurf_group
ADD CONSTRAINT sg_creator_fk_1_1527701982 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

