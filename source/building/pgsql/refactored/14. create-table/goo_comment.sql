-- Table: perseus.goo_comment
-- Source: SQL Server [dbo].[goo_comment]
-- Columns: 6

CREATE TABLE IF NOT EXISTS perseus.goo_comment (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    goo_id INTEGER NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    comment TEXT NOT NULL,
    category VARCHAR(20)
);
