ALTER TABLE perseus_dbo.cm_user
ADD CONSTRAINT ck_cm_user_len_login CHECK (length(login::text) <= 50);

