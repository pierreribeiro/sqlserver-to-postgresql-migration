ALTER TABLE perseus_dbo.unit
ADD CONSTRAINT ck_unit_len_name CHECK (length(name::text) <= 25);

