ALTER TABLE perseus_dbo.smurf_group
ADD CONSTRAINT ck_smurf_group_len_name CHECK (length(name::text) <= 150);

