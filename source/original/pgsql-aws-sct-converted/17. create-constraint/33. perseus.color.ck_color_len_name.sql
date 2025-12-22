ALTER TABLE perseus_dbo.color
ADD CONSTRAINT ck_color_len_name CHECK (length(name::text) <= 255);

