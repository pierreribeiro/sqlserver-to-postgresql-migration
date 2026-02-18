ALTER TABLE perseus_dbo.goo_comment
ADD CONSTRAINT ck_goo_comment_len_category CHECK (length(category::text) <= 20);

