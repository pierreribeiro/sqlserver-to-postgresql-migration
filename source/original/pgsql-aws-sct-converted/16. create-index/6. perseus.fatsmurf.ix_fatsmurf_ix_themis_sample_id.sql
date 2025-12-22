CREATE INDEX ix_fatsmurf_ix_themis_sample_id
ON perseus_dbo.fatsmurf
USING BTREE (themis_sample_id ASC)
WITH (FILLFACTOR = 90);

