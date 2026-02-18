ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT ck_fatsmurf_len_uid CHECK (length(uid::text) <= 50);

