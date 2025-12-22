ALTER TABLE perseus_dbo.person
ADD CONSTRAINT ck_person_len_domain_id CHECK (length(domain_id::text) <= 32);

