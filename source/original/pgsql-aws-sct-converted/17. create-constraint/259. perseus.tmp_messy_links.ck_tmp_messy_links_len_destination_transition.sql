ALTER TABLE perseus_dbo.tmp_messy_links
ADD CONSTRAINT ck_tmp_messy_links_len_destination_transition CHECK (length(destination_transition::text) <= 50);

