ALTER TABLE perseus_dbo.container
ADD CONSTRAINT ck_container_len_scope_id CHECK (length(scope_id::text) <= 50);

