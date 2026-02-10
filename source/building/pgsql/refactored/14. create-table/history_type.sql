-- Table: perseus.history_type
-- Source: SQL Server [dbo].[history_type]
-- Columns: 3

CREATE TABLE IF NOT EXISTS perseus.history_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL,
    format VARCHAR(250) NOT NULL
);
