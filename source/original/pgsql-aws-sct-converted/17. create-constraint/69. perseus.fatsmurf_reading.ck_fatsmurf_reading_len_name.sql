ALTER TABLE perseus_dbo.fatsmurf_reading
ADD CONSTRAINT ck_fatsmurf_reading_len_name CHECK (length(name::text) <= 150);

