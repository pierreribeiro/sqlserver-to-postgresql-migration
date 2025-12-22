ALTER TABLE perseus_dbo.perseus_user
ADD CONSTRAINT ck_perseus_user_len_login CHECK (length(login::text) <= 50);

