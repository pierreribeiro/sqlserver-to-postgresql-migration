ALTER TABLE perseus_dbo.perseus_user
ADD CONSTRAINT ck_perseus_user_len_domain_id CHECK (length(domain_id::text) <= 250);

