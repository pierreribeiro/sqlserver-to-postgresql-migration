ALTER TABLE perseus_dbo.smurf_group_member
ADD CONSTRAINT smurf_group_member_fk_2_1543702039 FOREIGN KEY (smurf_group_id) 
REFERENCES perseus_dbo.smurf_group (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

