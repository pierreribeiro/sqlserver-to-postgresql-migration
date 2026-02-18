ALTER TABLE perseus_dbo.cm_group
ADD CONSTRAINT ck_cm_group_len_name CHECK (length(name::text) <= 255);

