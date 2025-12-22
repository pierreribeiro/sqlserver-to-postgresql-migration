ALTER TABLE perseus_dbo.cm_user
ADD CONSTRAINT ck_cm_user_len_domain_id CHECK (length(domain_id::text) <= 32);

