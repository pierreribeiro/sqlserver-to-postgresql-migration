CREATE INDEX ix_history_value_ix_history_id_value
ON perseus_dbo.history_value
USING BTREE (history_id ASC)
WITH (FILLFACTOR = 70);

