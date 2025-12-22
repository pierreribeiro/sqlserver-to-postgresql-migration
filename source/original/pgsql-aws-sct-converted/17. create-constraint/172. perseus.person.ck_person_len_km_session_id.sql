ALTER TABLE perseus_dbo.person
ADD CONSTRAINT ck_person_len_km_session_id CHECK (length(km_session_id::text) <= 32);

