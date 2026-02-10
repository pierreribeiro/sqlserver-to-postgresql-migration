-- Table: perseus.scraper
-- Source: SQL Server [dbo].[Scraper]
-- Columns: 19

CREATE TABLE IF NOT EXISTS perseus.scraper (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    timestamp TIMESTAMP,
    message VARCHAR(255),
    file_type CHAR(1),
    filename VARCHAR(255),
    filename_saved_as VARCHAR(255),
    received_from VARCHAR(255),
    file BYTEA,
    result VARCHAR(1),
    complete BOOLEAN,
    scraper_id VARCHAR(50),
    scraping_started_on TIMESTAMP,
    scraping_finished_on TIMESTAMP,
    scraping_status VARCHAR(50),
    scraper_send_to TEXT,
    scraper_message TEXT,
    active CHAR(1),
    control_file_id INTEGER,
    document_id VARCHAR(25)
);
