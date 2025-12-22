ALTER TABLE perseus_dbo.cm_application_group
ADD CONSTRAINT ck_cm_application_group_len_label CHECK (length(label::text) <= 50);

