ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_scrapingstatus CHECK (length(scrapingstatus::text) <= 50);

