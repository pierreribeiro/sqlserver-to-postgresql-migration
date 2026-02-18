ALTER TABLE perseus_dbo.workflow_attachment
ADD CONSTRAINT workflow_attachment_fk_2_956660043 FOREIGN KEY (workflow_id) 
REFERENCES perseus_dbo.workflow (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

