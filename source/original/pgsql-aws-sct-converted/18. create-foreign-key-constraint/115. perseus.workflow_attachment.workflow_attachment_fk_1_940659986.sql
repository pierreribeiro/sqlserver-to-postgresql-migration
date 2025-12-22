ALTER TABLE perseus_dbo.workflow_attachment
ADD CONSTRAINT workflow_attachment_fk_1_940659986 FOREIGN KEY (added_by) 
REFERENCES perseus_dbo.perseus_user (id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

