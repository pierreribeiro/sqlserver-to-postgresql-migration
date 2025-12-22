ALTER TABLE perseus_dbo.poll
ADD CONSTRAINT ck_poll_len_value CHECK (length(value::text) <= 2048);

