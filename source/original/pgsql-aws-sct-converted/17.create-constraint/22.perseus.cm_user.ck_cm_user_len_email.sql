ALTER TABLE perseus_dbo.cm_user
ADD CONSTRAINT ck_cm_user_len_email CHECK (length(email::text) <= 255);

