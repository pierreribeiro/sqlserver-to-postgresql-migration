ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_filename CHECK (length(filename::text) <= 255);

