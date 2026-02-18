-- Table: perseus.goo_attachment
-- Source: SQL Server [dbo].[goo_attachment]
-- Columns: 9

CREATE TABLE IF NOT EXISTS perseus.goo_attachment (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    added_on TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    description VARCHAR(250),
    attachment_name VARCHAR(150) NOT NULL,
    attachment_mime_type VARCHAR(150),
    attachment BYTEA,
    goo_attachment_type_id INTEGER
);
