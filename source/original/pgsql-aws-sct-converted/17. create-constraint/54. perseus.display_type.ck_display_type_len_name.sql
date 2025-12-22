ALTER TABLE perseus_dbo.display_type
ADD CONSTRAINT ck_display_type_len_name CHECK (length(name::text) <= 50);

