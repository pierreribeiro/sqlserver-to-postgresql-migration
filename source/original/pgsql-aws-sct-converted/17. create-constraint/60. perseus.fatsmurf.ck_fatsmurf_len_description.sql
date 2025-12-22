ALTER TABLE perseus_dbo.fatsmurf
ADD CONSTRAINT ck_fatsmurf_len_description CHECK (length(description::text) <= 500);

