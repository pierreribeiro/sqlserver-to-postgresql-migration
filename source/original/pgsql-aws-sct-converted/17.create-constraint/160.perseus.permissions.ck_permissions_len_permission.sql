ALTER TABLE perseus_dbo.permissions
ADD CONSTRAINT ck_permissions_len_permission CHECK (length(permission::text) <= 1);

