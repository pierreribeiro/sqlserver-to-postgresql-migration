ALTER TABLE perseus_dbo.cm_application
ADD CONSTRAINT ck_cm_application_len_description CHECK (length(description::text) <= 255);

