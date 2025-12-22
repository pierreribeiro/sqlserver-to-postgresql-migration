ALTER TABLE perseus_dbo.display_layout
ADD CONSTRAINT ck_display_layout_len_name CHECK (length(name::text) <= 50);

