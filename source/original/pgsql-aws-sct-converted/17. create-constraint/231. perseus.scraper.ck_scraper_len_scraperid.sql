ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_scraperid CHECK (length(scraperid::text) <= 50);

