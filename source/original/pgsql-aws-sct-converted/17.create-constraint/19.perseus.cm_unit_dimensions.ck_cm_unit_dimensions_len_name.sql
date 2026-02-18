ALTER TABLE perseus_dbo.cm_unit_dimensions
ADD CONSTRAINT ck_cm_unit_dimensions_len_name CHECK (length(name::text) <= 50);

