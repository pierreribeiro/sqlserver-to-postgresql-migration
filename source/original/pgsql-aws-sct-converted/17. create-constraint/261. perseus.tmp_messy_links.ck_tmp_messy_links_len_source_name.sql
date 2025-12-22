ALTER TABLE perseus_dbo.tmp_messy_links
ADD CONSTRAINT ck_tmp_messy_links_len_source_name CHECK (length(source_name::text) <= 150);

