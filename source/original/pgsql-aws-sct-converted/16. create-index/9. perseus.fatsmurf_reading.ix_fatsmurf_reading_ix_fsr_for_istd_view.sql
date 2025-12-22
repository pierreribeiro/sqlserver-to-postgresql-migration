CREATE INDEX ix_fatsmurf_reading_ix_fsr_for_istd_view
ON perseus_dbo.fatsmurf_reading
USING BTREE (fatsmurf_id ASC) INCLUDE(id)
WITH (FILLFACTOR = 70);

