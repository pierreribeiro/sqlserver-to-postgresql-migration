ALTER TABLE perseus_dbo.person
ADD CONSTRAINT ck_person_len_email CHECK (length(email::text) <= 254);

