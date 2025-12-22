ALTER TABLE perseus_dbo.history_type
ADD CONSTRAINT ck_history_type_len_name CHECK (length(name::text) <= 50);

