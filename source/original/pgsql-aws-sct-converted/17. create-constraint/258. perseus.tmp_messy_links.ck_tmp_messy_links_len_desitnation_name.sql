ALTER TABLE perseus_dbo.tmp_messy_links
ADD CONSTRAINT ck_tmp_messy_links_len_desitnation_name CHECK (length(desitnation_name::text) <= 150);

