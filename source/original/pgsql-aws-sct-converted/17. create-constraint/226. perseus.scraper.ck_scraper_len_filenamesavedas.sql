ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_filenamesavedas CHECK (length(filenamesavedas::text) <= 255);

