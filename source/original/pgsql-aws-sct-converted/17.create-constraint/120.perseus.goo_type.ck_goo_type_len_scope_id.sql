ALTER TABLE perseus_dbo.goo_type
ADD CONSTRAINT ck_goo_type_len_scope_id CHECK (length(scope_id::text) <= 50);

