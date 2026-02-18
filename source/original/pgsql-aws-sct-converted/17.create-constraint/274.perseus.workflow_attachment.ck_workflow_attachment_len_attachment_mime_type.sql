ALTER TABLE perseus_dbo.workflow_attachment
ADD CONSTRAINT ck_workflow_attachment_len_attachment_mime_type CHECK (length(attachment_mime_type::text) <= 150);

