ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_message CHECK (length(message::text) <= 255);

