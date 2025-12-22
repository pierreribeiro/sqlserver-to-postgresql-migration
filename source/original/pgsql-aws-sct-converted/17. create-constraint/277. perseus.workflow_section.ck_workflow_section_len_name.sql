ALTER TABLE perseus_dbo.workflow_section
ADD CONSTRAINT ck_workflow_section_len_name CHECK (length(name::text) <= 150);

