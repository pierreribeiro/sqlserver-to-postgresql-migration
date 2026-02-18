ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_active CHECK (length(active::text) <= 1);

