ALTER TABLE perseus_dbo.perseus_user
ADD CONSTRAINT ck_perseus_user_len_mail CHECK (length(mail::text) <= 50);

