ALTER TABLE perseus_dbo.cm_unit
ADD CONSTRAINT ck_cm_unit_len_longname CHECK (length(longname::text) <= 50);

