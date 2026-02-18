ALTER TABLE perseus_dbo.permissions
ADD CONSTRAINT ck_permissions_len_emailaddress CHECK (length(emailaddress::text) <= 255);

