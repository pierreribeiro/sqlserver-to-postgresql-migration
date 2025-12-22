CREATE UNIQUE INDEX ix_goo_uniq_goo_uid
ON perseus_dbo.goo
USING BTREE (uid ASC)
WITH (FILLFACTOR = 90);

