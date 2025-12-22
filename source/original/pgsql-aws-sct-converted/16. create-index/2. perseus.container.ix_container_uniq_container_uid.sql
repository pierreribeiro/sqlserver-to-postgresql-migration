CREATE UNIQUE INDEX ix_container_uniq_container_uid
ON perseus_dbo.container
USING BTREE (uid ASC)
WITH (FILLFACTOR = 90);

