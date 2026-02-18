ALTER TABLE perseus_dbo.smurf_group_member
ADD CONSTRAINT smurf_group_member_fk_1_1431701640 FOREIGN KEY (smurf_id) 
REFERENCES perseus_dbo.smurf (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

