ALTER TABLE perseus_dbo.workflow
ADD CONSTRAINT workflow_creator_fk_1_673515020 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

