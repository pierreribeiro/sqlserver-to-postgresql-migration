ALTER TABLE perseus_dbo.cm_unit
ADD CONSTRAINT ck_cm_unit_len_name CHECK (length(name::text) <= 25);

