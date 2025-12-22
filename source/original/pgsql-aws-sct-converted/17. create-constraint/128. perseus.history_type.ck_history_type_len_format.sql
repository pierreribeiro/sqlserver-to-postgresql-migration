ALTER TABLE perseus_dbo.history_type
ADD CONSTRAINT ck_history_type_len_format CHECK (length(format::text) <= 250);

