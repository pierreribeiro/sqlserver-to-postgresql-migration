ALTER TABLE perseus_dbo.smurf_property
ADD CONSTRAINT ck_smurf_property_len_calculated CHECK (length(calculated::text) <= 250);

