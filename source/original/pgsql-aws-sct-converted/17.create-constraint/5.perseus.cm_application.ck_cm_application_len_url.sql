ALTER TABLE perseus_dbo.cm_application
ADD CONSTRAINT ck_cm_application_len_url CHECK (length(url::text) <= 255);

