CREATE INDEX ix_scraper_idx_active
ON perseus_dbo.scraper
USING BTREE (active ASC);

