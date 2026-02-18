ALTER TABLE perseus_dbo.property_option
ADD CONSTRAINT ck_property_option_len_label CHECK (length(label::text) <= 150);

