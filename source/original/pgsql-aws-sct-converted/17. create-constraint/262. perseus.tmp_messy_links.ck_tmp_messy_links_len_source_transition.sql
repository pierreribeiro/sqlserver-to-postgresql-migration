ALTER TABLE perseus_dbo.tmp_messy_links
ADD CONSTRAINT ck_tmp_messy_links_len_source_transition CHECK (length(source_transition::text) <= 50);

