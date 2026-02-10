-- Table: perseus.submission
-- Source: SQL Server [dbo].[submission]
-- Columns: 4

CREATE TABLE IF NOT EXISTS perseus.submission (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    submitter_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL,
    label VARCHAR(100)
);
