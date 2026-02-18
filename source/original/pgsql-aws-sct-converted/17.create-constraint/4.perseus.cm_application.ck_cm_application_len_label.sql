ALTER TABLE perseus_dbo.cm_application
ADD CONSTRAINT ck_cm_application_len_label CHECK (length(label::text) <= 50);

