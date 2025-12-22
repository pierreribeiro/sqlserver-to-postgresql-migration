ALTER TABLE perseus_dbo.property
ADD CONSTRAINT ck_property_len_name CHECK (length(name::text) <= 100);

