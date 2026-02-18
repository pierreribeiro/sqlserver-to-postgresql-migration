ALTER TABLE perseus_dbo.history_value
ADD CONSTRAINT ck_history_value_len_value CHECK (length(value::text) <= 250);

