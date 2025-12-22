ALTER TABLE perseus_dbo.workflow_section
ADD CONSTRAINT workflow_section_fk_1_705515134 FOREIGN KEY (workflow_id) 
REFERENCES perseus_dbo.workflow (id)
ON UPDATE NO ACTION
ON DELETE CASCADE;

