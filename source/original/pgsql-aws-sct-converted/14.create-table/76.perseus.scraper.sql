CREATE TABLE perseus_dbo.scraper(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    timestamp TIMESTAMP WITHOUT TIME ZONE,
    message CITEXT,
    filetype CITEXT,
    filename CITEXT,
    filenamesavedas CITEXT,
    receivedfrom CITEXT,
    file BYTEA,
    result CITEXT,
    complete NUMERIC(1,0),
    scraperid CITEXT,
    scrapingstartedon TIMESTAMP WITHOUT TIME ZONE,
    scrapingfinishedon TIMESTAMP WITHOUT TIME ZONE,
    scrapingstatus CITEXT,
    scrapersendto CITEXT,
    scrapermessage CITEXT,
    active CITEXT,
    controlfileid INTEGER,
    documentid CITEXT
)
        WITH (
        OIDS=FALSE
        );

