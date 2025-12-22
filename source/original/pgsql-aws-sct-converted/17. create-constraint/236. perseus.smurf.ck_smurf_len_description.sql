ALTER TABLE perseus_dbo.smurf
ADD CONSTRAINT ck_smurf_len_description CHECK (length(description::text) <= 500);

