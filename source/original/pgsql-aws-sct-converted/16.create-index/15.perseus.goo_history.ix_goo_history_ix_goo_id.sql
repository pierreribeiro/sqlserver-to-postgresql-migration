CREATE INDEX ix_goo_history_ix_goo_id
ON perseus_dbo.goo_history
USING BTREE (goo_id ASC)
WITH (FILLFACTOR = 70);

