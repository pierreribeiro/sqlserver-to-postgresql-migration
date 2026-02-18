ALTER TABLE perseus_dbo.cm_user
ADD CONSTRAINT ck_cm_user_len_name CHECK (length(name::text) <= 255);

