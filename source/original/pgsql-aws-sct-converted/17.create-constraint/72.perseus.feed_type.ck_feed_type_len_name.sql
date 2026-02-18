ALTER TABLE perseus_dbo.feed_type
ADD CONSTRAINT ck_feed_type_len_name CHECK (length(name::text) <= 100);

