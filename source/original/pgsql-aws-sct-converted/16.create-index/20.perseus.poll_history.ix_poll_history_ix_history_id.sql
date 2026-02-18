CREATE INDEX ix_poll_history_ix_history_id
ON perseus_dbo.poll_history
USING BTREE (poll_id ASC) INCLUDE(history_id)
WITH (FILLFACTOR = 70);

