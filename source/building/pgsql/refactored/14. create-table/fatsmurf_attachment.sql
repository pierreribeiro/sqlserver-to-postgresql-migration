-- Table: perseus.fatsmurf_attachment
-- Source: SQL Server [dbo].[fatsmurf_attachment]
-- Columns: 8

CREATE TABLE IF NOT EXISTS perseus.fatsmurf_attachment (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    fatsmurf_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    description TEXT NOT NULL,
    attachment_name VARCHAR(150),
    attachment_mime_type VARCHAR(150),
    attachment BYTEA
);
