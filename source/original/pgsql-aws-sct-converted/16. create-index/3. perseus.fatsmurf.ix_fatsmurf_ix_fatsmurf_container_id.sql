CREATE INDEX ix_fatsmurf_ix_fatsmurf_container_id
ON perseus_dbo.fatsmurf
USING BTREE (container_id ASC)
WITH (FILLFACTOR = 90);

