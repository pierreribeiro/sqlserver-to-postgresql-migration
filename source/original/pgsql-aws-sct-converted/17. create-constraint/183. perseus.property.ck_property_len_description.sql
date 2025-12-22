ALTER TABLE perseus_dbo.property
ADD CONSTRAINT ck_property_len_description CHECK (length(description::text) <= 500);

