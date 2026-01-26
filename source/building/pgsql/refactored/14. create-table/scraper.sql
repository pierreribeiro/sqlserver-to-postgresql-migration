-- ============================================================================
-- Object: scraper
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: Web scraper configuration and results tracking
-- ============================================================================

DROP TABLE IF EXISTS perseus.scraper CASCADE;

CREATE TABLE perseus.scraper (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    timestamp TIMESTAMP,
    message TEXT,
    filetype VARCHAR(100),
    filename VARCHAR(500),
    filenamesavedas VARCHAR(500),
    receivedfrom VARCHAR(200),
    file BYTEA,
    result TEXT,
    complete BOOLEAN,
    scraperid VARCHAR(100),
    scrapingstartedon TIMESTAMP,
    scrapingfinishedon TIMESTAMP,
    scrapingstatus VARCHAR(100),
    scrapersendto VARCHAR(200),
    scrapermessage TEXT,
    active VARCHAR(50),
    controlfileid INTEGER,
    documentid VARCHAR(100),

    CONSTRAINT pk_scraper PRIMARY KEY (id)
);

CREATE INDEX idx_scraper_status ON perseus.scraper(scrapingstatus);
CREATE INDEX idx_scraper_complete ON perseus.scraper(complete);
CREATE INDEX idx_scraper_timestamp ON perseus.scraper(timestamp);

COMMENT ON TABLE perseus.scraper IS
'Web scraper configuration and results tracking. Stores scraped files and metadata. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.scraper.file IS 'Binary file data (BYTEA)';
COMMENT ON COLUMN perseus.scraper.complete IS 'True if scraping completed successfully';
