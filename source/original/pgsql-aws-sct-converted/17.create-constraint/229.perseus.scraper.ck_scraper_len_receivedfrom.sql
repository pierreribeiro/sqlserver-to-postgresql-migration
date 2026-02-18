ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_receivedfrom CHECK (length(receivedfrom::text) <= 255);

