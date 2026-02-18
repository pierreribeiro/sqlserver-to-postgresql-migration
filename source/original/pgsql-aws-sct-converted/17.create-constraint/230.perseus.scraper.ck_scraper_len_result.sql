ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_result CHECK (length(result::text) <= 1);

