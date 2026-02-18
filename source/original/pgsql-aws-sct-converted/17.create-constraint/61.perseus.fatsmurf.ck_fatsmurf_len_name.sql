ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT ck_fatsmurf_len_name CHECK (length(name::text) <= 150);

