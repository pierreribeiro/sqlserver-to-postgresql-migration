CREATE UNIQUE INDEX ix_fatsmurf_uniq_fs_uid
ON perseus_dbo.fatsmurf
USING BTREE (uid ASC)
WITH (FILLFACTOR = 70);

