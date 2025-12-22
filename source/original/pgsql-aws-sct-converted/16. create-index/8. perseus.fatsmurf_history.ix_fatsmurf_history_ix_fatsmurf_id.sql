CREATE INDEX ix_fatsmurf_history_ix_fatsmurf_id
ON perseus_dbo.fatsmurf_history
USING BTREE (fatsmurf_id ASC)
WITH (FILLFACTOR = 70);

