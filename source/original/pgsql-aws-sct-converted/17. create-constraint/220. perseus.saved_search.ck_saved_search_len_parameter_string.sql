ALTER TABLE perseus_dbo.saved_search
ADD CONSTRAINT ck_saved_search_len_parameter_string CHECK (length(parameter_string::text) <= 2500);

