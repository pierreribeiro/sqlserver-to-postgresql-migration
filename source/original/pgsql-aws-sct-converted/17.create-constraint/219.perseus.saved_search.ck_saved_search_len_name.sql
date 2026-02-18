ALTER TABLE perseus_dbo.saved_search
ADD CONSTRAINT ck_saved_search_len_name CHECK (length(name::text) <= 128);

