ALTER TABLE perseus_dbo.scraper
ADD CONSTRAINT ck_scraper_len_documentid CHECK (length(documentid::text) <= 25);

