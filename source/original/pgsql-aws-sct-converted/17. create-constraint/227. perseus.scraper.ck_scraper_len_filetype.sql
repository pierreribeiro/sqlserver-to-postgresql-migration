ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_filetype CHECK (length(filetype::text) <= 1);

