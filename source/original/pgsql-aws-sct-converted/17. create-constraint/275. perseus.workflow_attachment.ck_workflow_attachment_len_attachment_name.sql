ALTER TABLE perseus_dbo.workflow_attachment
ADD CONSTRAINT ck_workflow_attachment_len_attachment_name CHECK (length(attachment_name::text) <= 150);

