ALTER TABLE perseus_dbo.perseus_user
ADD CONSTRAINT ck_perseus_user_len_name CHECK (length(name::text) <= 128);

