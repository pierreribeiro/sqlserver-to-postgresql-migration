ALTER TABLE perseus_dbo.cm_project
ADD CONSTRAINT ck_cm_project_len_label CHECK (length(label::text) <= 255);

