ALTER TABLE perseus_dbo.unit
ADD CONSTRAINT ck_unit_len_description CHECK (length(description::text) <= 150);

