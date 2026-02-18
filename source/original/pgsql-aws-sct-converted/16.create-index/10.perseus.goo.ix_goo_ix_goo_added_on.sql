CREATE INDEX ix_goo_ix_goo_added_on
ON perseus_dbo.goo
USING BTREE (added_on ASC) INCLUDE(uid, container_id)
WITH (FILLFACTOR = 90);

