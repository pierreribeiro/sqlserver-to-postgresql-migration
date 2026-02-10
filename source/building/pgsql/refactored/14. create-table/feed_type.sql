-- Table: perseus.feed_type
-- Source: SQL Server [dbo].[feed_type]
-- Columns: 10

CREATE TABLE IF NOT EXISTS perseus.feed_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    added_by INTEGER NOT NULL,
    updated_by_id INTEGER,
    name VARCHAR(100),
    description TEXT,
    correction_method TEXT NOT NULL DEFAULT 'SIMPLE',
    correction_factor DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    disabled BOOLEAN NOT NULL DEFAULT FALSE,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
