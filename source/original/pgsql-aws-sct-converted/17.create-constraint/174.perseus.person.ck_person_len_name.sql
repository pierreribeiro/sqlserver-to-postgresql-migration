ALTER TABLE perseus_dbo.person
ADD CONSTRAINT ck_person_len_name CHECK (length(name::text) <= 255);

