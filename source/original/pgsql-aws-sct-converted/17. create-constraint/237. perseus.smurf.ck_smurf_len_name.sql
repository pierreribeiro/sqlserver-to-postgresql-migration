ALTER TABLE perseus_dbo.smurf
ADD CONSTRAINT ck_smurf_len_name CHECK (length(name::text) <= 150);

