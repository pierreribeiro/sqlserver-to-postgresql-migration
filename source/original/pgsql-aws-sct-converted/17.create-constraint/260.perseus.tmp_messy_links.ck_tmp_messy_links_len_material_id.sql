ALTER TABLE perseus_dbo.tmp_messy_links
ADD CONSTRAINT ck_tmp_messy_links_len_material_id CHECK (length(material_id::text) <= 50);

