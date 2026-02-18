-- Table: perseus.workflow_attachment
-- Source: SQL Server [dbo].[workflow_attachment]
-- Columns: 7

CREATE TABLE IF NOT EXISTS perseus.workflow_attachment (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    workflow_id INTEGER NOT NULL,
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    attachment_name VARCHAR(150),
    attachment_mime_type VARCHAR(150),
    attachment BYTEA
);
