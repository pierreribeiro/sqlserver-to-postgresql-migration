ALTER TABLE perseus_dbo.prefix_incrementor
ADD CONSTRAINT ck_prefix_incrementor_len_prefix CHECK (length(prefix::text) <= 10);

