ALTER TABLE perseus_dbo.person
ADD CONSTRAINT ck_person_len_login CHECK (length(login::text) <= 50);

