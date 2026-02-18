-- ============================================================================
-- File: 00-idx_scraper_active.sql
-- Table: scraper
-- Index: idx_scraper_active
-- Original: Scraper.idx_ACTIVE
-- ============================================================================
-- Description: Index on scraper active status for filtering active scrapers
-- Columns: scrapingstatus (was "Active" in SQL Server, column renamed)
-- Type: NONCLUSTERED → B-tree
-- ============================================================================

CREATE INDEX idx_scraper_active
  ON perseus.scraper (scrapingstatus)
  TABLESPACE pg_default;

COMMENT ON INDEX perseus.idx_scraper_active IS
'Index on scraper active status for filtering active scrapers.
Original SQL Server: [idx_ACTIVE] ON [dbo].[Scraper] ([Active] ASC)
Column renamed: Active → scrapingstatus';
