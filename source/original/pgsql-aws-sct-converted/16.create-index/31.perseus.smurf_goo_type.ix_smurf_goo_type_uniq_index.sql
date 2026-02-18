CREATE UNIQUE INDEX ix_smurf_goo_type_uniq_index
ON perseus_dbo.smurf_goo_type
USING BTREE (smurf_id ASC, goo_type_id ASC, is_input ASC);

