ALTER TABLE perseus_dbo.cm_unit
ADD CONSTRAINT ck_cm_unit_len_description CHECK (length(description::text) <= 150);

